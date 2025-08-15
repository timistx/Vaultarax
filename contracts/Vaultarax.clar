;; Vaultarax Core Contract
;; Decentralized treasure hunt protocol for Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-vault-not-found (err u101))
(define-constant err-vault-already-solved (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-invalid-solution (err u104))
(define-constant err-vault-expired (err u105))
(define-constant err-invalid-difficulty (err u106))
(define-constant err-self-solve-forbidden (err u107))
(define-constant err-invalid-hash (err u108))

;; Data Variables
(define-data-var vault-counter uint u0)
(define-data-var total-rewards uint u0)

;; Data Maps
(define-map vaults uint {
    creator: principal,
    riddle-hash: (buff 32),
    solution-hash: (buff 32),
    reward-amount: uint,
    difficulty: uint,
    created-height: uint,
    expiry-height: uint,
    solved: bool,
    solver: (optional principal)
})

(define-map user-stats principal {
    vaults-created: uint,
    vaults-solved: uint,
    total-earned: uint,
    total-spent: uint
})

;; Private Functions
(define-private (is-valid-difficulty (difficulty uint))
    (and (>= difficulty u1) (<= difficulty u5))
)

(define-private (is-valid-hash (hash (buff 32)))
    (is-eq (len hash) u32)
)

(define-private (calculate-expiry-height (difficulty uint))
    (+ stacks-block-height 
       (if (<= difficulty u2) u1008 ;; ~1 week for easy
           (if (<= difficulty u3) u4320 ;; ~1 month for medium  
               u8640))) ;; ~2 months for hard
)

(define-private (update-user-stats-create (user principal) (amount uint))
    (let ((current-stats (default-to {vaults-created: u0, vaults-solved: u0, total-earned: u0, total-spent: u0} 
                                   (map-get? user-stats user))))
        (map-set user-stats user {
            vaults-created: (+ (get vaults-created current-stats) u1),
            vaults-solved: (get vaults-solved current-stats),
            total-earned: (get total-earned current-stats),
            total-spent: (+ (get total-spent current-stats) amount)
        })
    )
)

(define-private (update-user-stats-solve (user principal) (amount uint))
    (let ((current-stats (default-to {vaults-created: u0, vaults-solved: u0, total-earned: u0, total-spent: u0} 
                                   (map-get? user-stats user))))
        (map-set user-stats user {
            vaults-created: (get vaults-created current-stats),
            vaults-solved: (+ (get vaults-solved current-stats) u1),
            total-earned: (+ (get total-earned current-stats) amount),
            total-spent: (get total-spent current-stats)
        })
    )
)

;; Public Functions
(define-public (create-vault (riddle-hash (buff 32)) (solution-hash (buff 32)) (reward-amount uint) (difficulty uint))
    (let ((vault-id (+ (var-get vault-counter) u1))
          (expiry-height (calculate-expiry-height difficulty)))
        (asserts! (is-valid-hash riddle-hash) err-invalid-hash)
        (asserts! (is-valid-hash solution-hash) err-invalid-hash)
        (asserts! (is-valid-difficulty difficulty) err-invalid-difficulty)
        (asserts! (> reward-amount u0) err-insufficient-payment)
        
        ;; Transfer STX to contract
        (try! (stx-transfer? reward-amount tx-sender (as-contract tx-sender)))
        
        ;; Create vault
        (map-set vaults vault-id {
            creator: tx-sender,
            riddle-hash: riddle-hash,
            solution-hash: solution-hash,
            reward-amount: reward-amount,
            difficulty: difficulty,
            created-height: stacks-block-height,
            expiry-height: expiry-height,
            solved: false,
            solver: none
        })
        
        ;; Update counters and stats
        (var-set vault-counter vault-id)
        (var-set total-rewards (+ (var-get total-rewards) reward-amount))
        (update-user-stats-create tx-sender reward-amount)
        
        (ok vault-id)
    )
)

(define-public (solve-vault (vault-id uint) (solution (buff 32)))
    (let ((vault-data (unwrap! (map-get? vaults vault-id) err-vault-not-found)))
        (asserts! (is-valid-hash solution) err-invalid-hash)
        (asserts! (not (get solved vault-data)) err-vault-already-solved)
        (asserts! (< stacks-block-height (get expiry-height vault-data)) err-vault-expired)
        (asserts! (not (is-eq tx-sender (get creator vault-data))) err-self-solve-forbidden)
        (asserts! (is-eq (sha256 solution) (get solution-hash vault-data)) err-invalid-solution)
        
        ;; Transfer reward to solver
        (try! (as-contract (stx-transfer? (get reward-amount vault-data) tx-sender tx-sender)))
        
        ;; Mark vault as solved
        (map-set vaults vault-id (merge vault-data {
            solved: true,
            solver: (some tx-sender)
        }))
        
        ;; Update solver stats
        (update-user-stats-solve tx-sender (get reward-amount vault-data))
        
        (ok (get reward-amount vault-data))
    )
)

(define-public (claim-expired-vault (vault-id uint))
    (let ((vault-data (unwrap! (map-get? vaults vault-id) err-vault-not-found)))
        (asserts! (is-eq tx-sender (get creator vault-data)) err-owner-only)
        (asserts! (not (get solved vault-data)) err-vault-already-solved)
        (asserts! (>= stacks-block-height (get expiry-height vault-data)) err-vault-expired)
        
        ;; Return reward to creator
        (try! (as-contract (stx-transfer? (get reward-amount vault-data) tx-sender (get creator vault-data))))
        
        ;; Mark as expired/solved to prevent double claiming
        (map-set vaults vault-id (merge vault-data {solved: true}))
        
        (ok (get reward-amount vault-data))
    )
)

;; Read-only Functions
(define-read-only (get-vault (vault-id uint))
    (map-get? vaults vault-id)
)

(define-read-only (get-vault-count)
    (var-get vault-counter)
)

(define-read-only (get-user-stats (user principal))
    (map-get? user-stats user)
)

(define-read-only (get-total-rewards)
    (var-get total-rewards)
)

(define-read-only (is-vault-active (vault-id uint))
    (match (map-get? vaults vault-id)
        vault-data (and (not (get solved vault-data)) 
                       (< stacks-block-height (get expiry-height vault-data)))
        false
    )
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)