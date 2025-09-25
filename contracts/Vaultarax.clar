;; Vaultarax Core Contract
;; Decentralized treasure hunt protocol for Stacks blockchain with multi-token support

;; Traits
(define-trait sip-010-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
        (get-decimals () (response uint uint))
        (get-balance (principal) (response uint uint))
        (get-total-supply () (response uint uint))
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)

(define-trait nft-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response (optional principal) uint))
        (get-last-token-id () (response uint uint))
        (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
    )
)

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
(define-constant err-invalid-token-type (err u109))
(define-constant err-invalid-token-contract (err u110))
(define-constant err-token-transfer-failed (err u111))
(define-constant err-nft-transfer-failed (err u112))
(define-constant err-invalid-nft-id (err u113))
(define-constant err-nft-not-owned (err u114))

;; Token type constants
(define-constant token-type-stx u1)
(define-constant token-type-sip010 u2)
(define-constant token-type-nft u3)

;; Data Variables
(define-data-var vault-counter uint u0)
(define-data-var total-stx-rewards uint u0)

;; Data Maps
(define-map vaults uint {
    creator: principal,
    riddle-hash: (buff 32),
    solution-hash: (buff 32),
    reward-amount: uint,
    token-type: uint,
    token-contract: (optional principal),
    nft-id: (optional uint),
    difficulty: uint,
    created-height: uint,
    expiry-height: uint,
    solved: bool,
    solver: (optional principal)
})

(define-map user-stats principal {
    vaults-created: uint,
    vaults-solved: uint,
    total-stx-earned: uint,
    total-stx-spent: uint
})

(define-map supported-tokens principal bool)

;; Private Functions
(define-private (is-valid-difficulty (difficulty uint))
    (and (>= difficulty u1) (<= difficulty u5))
)

(define-private (is-valid-hash (hash (buff 32)))
    (is-eq (len hash) u32)
)

(define-private (is-valid-token-type (token-type uint))
    (or (is-eq token-type token-type-stx)
        (is-eq token-type token-type-sip010)
        (is-eq token-type token-type-nft))
)

(define-private (is-valid-nft-id (nft-id uint))
    (> nft-id u0)
)

(define-private (is-valid-token-contract (token-contract principal))
    (not (is-eq token-contract tx-sender))
)

(define-private (calculate-expiry-height (difficulty uint))
    (+ stacks-block-height 
       (if (<= difficulty u2) u1008 ;; ~1 week for easy
           (if (<= difficulty u3) u4320 ;; ~1 month for medium  
               u8640))) ;; ~2 months for hard
)

(define-private (update-user-stats-create (user principal) (amount uint) (token-type uint))
    (let ((current-stats (default-to {vaults-created: u0, vaults-solved: u0, total-stx-earned: u0, total-stx-spent: u0} 
                                   (map-get? user-stats user))))
        (map-set user-stats user {
            vaults-created: (+ (get vaults-created current-stats) u1),
            vaults-solved: (get vaults-solved current-stats),
            total-stx-earned: (get total-stx-earned current-stats),
            total-stx-spent: (if (is-eq token-type token-type-stx) 
                               (+ (get total-stx-spent current-stats) amount)
                               (get total-stx-spent current-stats))
        })
    )
)

(define-private (update-user-stats-solve (user principal) (amount uint) (token-type uint))
    (let ((current-stats (default-to {vaults-created: u0, vaults-solved: u0, total-stx-earned: u0, total-stx-spent: u0} 
                                   (map-get? user-stats user))))
        (map-set user-stats user {
            vaults-created: (get vaults-created current-stats),
            vaults-solved: (+ (get vaults-solved current-stats) u1),
            total-stx-earned: (if (is-eq token-type token-type-stx) 
                               (+ (get total-stx-earned current-stats) amount)
                               (get total-stx-earned current-stats)),
            total-stx-spent: (get total-stx-spent current-stats)
        })
    )
)

(define-private (transfer-reward-to-solver (vault-data {creator: principal, riddle-hash: (buff 32), solution-hash: (buff 32), reward-amount: uint, token-type: uint, token-contract: (optional principal), nft-id: (optional uint), difficulty: uint, created-height: uint, expiry-height: uint, solved: bool, solver: (optional principal)}) (solver principal))
    (let ((token-type (get token-type vault-data))
          (reward-amount (get reward-amount vault-data))
          (token-contract (get token-contract vault-data))
          (nft-id (get nft-id vault-data)))
        (if (is-eq token-type token-type-stx)
            (as-contract (stx-transfer? reward-amount tx-sender solver))
            err-invalid-token-type)
    )
)

(define-private (transfer-reward-to-creator (vault-data {creator: principal, riddle-hash: (buff 32), solution-hash: (buff 32), reward-amount: uint, token-type: uint, token-contract: (optional principal), nft-id: (optional uint), difficulty: uint, created-height: uint, expiry-height: uint, solved: bool, solver: (optional principal)}) (creator principal))
    (let ((token-type (get token-type vault-data))
          (reward-amount (get reward-amount vault-data))
          (token-contract (get token-contract vault-data))
          (nft-id (get nft-id vault-data)))
        (if (is-eq token-type token-type-stx)
            (as-contract (stx-transfer? reward-amount tx-sender creator))
            err-invalid-token-type)
    )
)

;; Public Functions
(define-public (create-stx-vault (riddle-hash (buff 32)) (solution-hash (buff 32)) (reward-amount uint) (difficulty uint))
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
            token-type: token-type-stx,
            token-contract: none,
            nft-id: none,
            difficulty: difficulty,
            created-height: stacks-block-height,
            expiry-height: expiry-height,
            solved: false,
            solver: none
        })
        
        ;; Update counters and stats
        (var-set vault-counter vault-id)
        (var-set total-stx-rewards (+ (var-get total-stx-rewards) reward-amount))
        (update-user-stats-create tx-sender reward-amount token-type-stx)
        
        (ok vault-id)
    )
)

(define-public (create-sip010-vault (riddle-hash (buff 32)) (solution-hash (buff 32)) (reward-amount uint) (token-contract <sip-010-trait>) (difficulty uint))
    (let ((vault-id (+ (var-get vault-counter) u1))
          (expiry-height (calculate-expiry-height difficulty))
          (token-principal (contract-of token-contract)))
        (asserts! (is-valid-hash riddle-hash) err-invalid-hash)
        (asserts! (is-valid-hash solution-hash) err-invalid-hash)
        (asserts! (is-valid-difficulty difficulty) err-invalid-difficulty)
        (asserts! (> reward-amount u0) err-insufficient-payment)
        (asserts! (is-valid-token-contract token-principal) err-invalid-token-contract)
        (asserts! (default-to false (map-get? supported-tokens token-principal)) err-invalid-token-contract)
        
        ;; Transfer SIP-010 tokens to contract
        (try! (contract-call? token-contract transfer reward-amount tx-sender (as-contract tx-sender) none))
        
        ;; Create vault
        (map-set vaults vault-id {
            creator: tx-sender,
            riddle-hash: riddle-hash,
            solution-hash: solution-hash,
            reward-amount: reward-amount,
            token-type: token-type-sip010,
            token-contract: (some token-principal),
            nft-id: none,
            difficulty: difficulty,
            created-height: stacks-block-height,
            expiry-height: expiry-height,
            solved: false,
            solver: none
        })
        
        ;; Update counters and stats
        (var-set vault-counter vault-id)
        (update-user-stats-create tx-sender reward-amount token-type-sip010)
        
        (ok vault-id)
    )
)

(define-public (create-nft-vault (riddle-hash (buff 32)) (solution-hash (buff 32)) (nft-contract <nft-trait>) (nft-id uint) (difficulty uint))
    (let ((vault-id (+ (var-get vault-counter) u1))
          (expiry-height (calculate-expiry-height difficulty))
          (token-principal (contract-of nft-contract)))
        (asserts! (is-valid-hash riddle-hash) err-invalid-hash)
        (asserts! (is-valid-hash solution-hash) err-invalid-hash)
        (asserts! (is-valid-difficulty difficulty) err-invalid-difficulty)
        (asserts! (is-valid-nft-id nft-id) err-invalid-nft-id)
        (asserts! (is-valid-token-contract token-principal) err-invalid-token-contract)
        (asserts! (default-to false (map-get? supported-tokens token-principal)) err-invalid-token-contract)
        
        ;; Transfer NFT to contract
        (try! (contract-call? nft-contract transfer nft-id tx-sender (as-contract tx-sender)))
        
        ;; Create vault
        (map-set vaults vault-id {
            creator: tx-sender,
            riddle-hash: riddle-hash,
            solution-hash: solution-hash,
            reward-amount: u1, ;; NFTs have no amount, using 1 for consistency
            token-type: token-type-nft,
            token-contract: (some token-principal),
            nft-id: (some nft-id),
            difficulty: difficulty,
            created-height: stacks-block-height,
            expiry-height: expiry-height,
            solved: false,
            solver: none
        })
        
        ;; Update counters and stats
        (var-set vault-counter vault-id)
        (update-user-stats-create tx-sender u1 token-type-nft)
        
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
        (try! (transfer-reward-to-solver vault-data tx-sender))
        
        ;; Mark vault as solved
        (map-set vaults vault-id (merge vault-data {
            solved: true,
            solver: (some tx-sender)
        }))
        
        ;; Update solver stats
        (update-user-stats-solve tx-sender (get reward-amount vault-data) (get token-type vault-data))
        
        (ok (get reward-amount vault-data))
    )
)

(define-public (claim-expired-vault (vault-id uint))
    (let ((vault-data (unwrap! (map-get? vaults vault-id) err-vault-not-found)))
        (asserts! (is-eq tx-sender (get creator vault-data)) err-owner-only)
        (asserts! (not (get solved vault-data)) err-vault-already-solved)
        (asserts! (>= stacks-block-height (get expiry-height vault-data)) err-vault-expired)
        
        ;; Return reward to creator
        (try! (transfer-reward-to-creator vault-data (get creator vault-data)))
        
        ;; Mark as expired/solved to prevent double claiming
        (map-set vaults vault-id (merge vault-data {solved: true}))
        
        (ok (get reward-amount vault-data))
    )
)

(define-public (add-supported-token (token-contract principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-token-contract token-contract) err-invalid-token-contract)
        (map-set supported-tokens token-contract true)
        (ok true)
    )
)

(define-public (remove-supported-token (token-contract principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-valid-token-contract token-contract) err-invalid-token-contract)
        (map-delete supported-tokens token-contract)
        (ok true)
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

(define-read-only (get-total-stx-rewards)
    (var-get total-stx-rewards)
)

(define-read-only (is-vault-active (vault-id uint))
    (match (map-get? vaults vault-id)
        vault-data (and (not (get solved vault-data)) 
                       (< stacks-block-height (get expiry-height vault-data)))
        false
    )
)

(define-read-only (is-token-supported (token-contract principal))
    (default-to false (map-get? supported-tokens token-contract))
)

(define-read-only (get-contract-stx-balance)
    (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-vault-reward-info (vault-id uint))
    (match (map-get? vaults vault-id)
        vault-data (ok {
            reward-amount: (get reward-amount vault-data),
            token-type: (get token-type vault-data),
            token-contract: (get token-contract vault-data),
            nft-id: (get nft-id vault-data)
        })
        err-vault-not-found
    )
)