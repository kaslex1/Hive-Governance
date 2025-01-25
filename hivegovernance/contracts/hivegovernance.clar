;; Hive Governance Contract
;; Community-driven decision making and treasury management

;; Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-MOTION-NOT-FOUND (err u101))
(define-constant ERR-LOW-BALANCE (err u102))
(define-constant ERR-DUPLICATE-VOTE (err u103))
(define-constant ERR-MOTION-TIMEOUT (err u104))
(define-constant ERR-INVALID-POWER (err u105))
(define-constant ERR-BAD-TITLE (err u106))
(define-constant ERR-BAD-DETAILS (err u107))
(define-constant ERR-BAD-VALUE (err u108))
(define-constant ERR-BAD-TARGET (err u109))
(define-constant ERR-BLANK-TITLE (err u110))
(define-constant ERR-BLANK-DETAILS (err u111))
(define-constant ERR-ZERO-VALUE (err u112))

(define-constant DECISION_WINDOW u144)
(define-constant MIN_MOTION_VALUE u1000000)
(define-constant MAX_CITIZEN_POWER u1000000)
(define-constant MIN_CITIZEN_POWER u1)

(define-trait staking-vault-trait
    (
        (stake (uint) (response bool uint))
        (unstake (uint) (response bool uint))
        (get-staked-balance (principal) (response uint uint))
    )
)

;; Data Maps
(define-map motions
    uint
    {
        initiator: principal,
        title: (string-ascii 50),
        details: (string-ascii 500),
        value: uint,
        target: principal,
        start-block: uint,
        support: uint,
        oppose: uint,
        completed: bool
    }
)

(define-map ballot-box
    {motion-id: uint, citizen: principal}
    bool
)

(define-map citizen-power
    principal
    uint
)

;; Data Variables
(define-data-var motion-count uint u0)
(define-data-var hive-admin principal tx-sender)
(define-data-var citizen-count uint u0)

;; Read-only functions
(define-read-only (get-motion (motion-id uint))
    (map-get? motions motion-id)
)

(define-read-only (get-power (citizen principal))
    (default-to u0 (map-get? citizen-power citizen))
)

(define-read-only (has-cast-vote (motion-id uint) (citizen principal))
    (is-some (map-get? ballot-box {motion-id: motion-id, citizen: citizen}))
)

;; Validation functions
(define-private (is-valid-power (power uint))
    (and 
        (>= power MIN_CITIZEN_POWER)
        (<= power MAX_CITIZEN_POWER)
    )
)

(define-private (is-valid-title (title (string-ascii 50)))
    (and
        (not (is-eq title ""))
        (<= (len title) u50)
    )
)

(define-private (is-valid-details (details (string-ascii 500)))
    (and
        (not (is-eq details ""))
        (<= (len details) u500)
    )
)

(define-private (is-valid-value (value uint))
    (and
        (> value u0)
        (>= value MIN_MOTION_VALUE)
    )
)

(define-private (is-valid-target (target principal))
    (and
        (not (is-eq target tx-sender))
        (not (is-eq target (var-get hive-admin)))
    )
)

;; Private functions
(define-private (is-citizen (address principal))
    (> (get-power address) u0)
)

(define-private (check-motion-active (motion-id uint))
    (let (
        (motion (unwrap! (get-motion motion-id) false))
        (current-block block-height)
    )
    (and
        (not (get completed motion))
        (<= current-block (+ (get start-block motion) DECISION_WINDOW))
    ))
)

;; Public functions
(define-public (add-citizen (address principal) (power uint))
    (begin
        (asserts! (is-eq tx-sender (var-get hive-admin)) ERR-UNAUTHORIZED)
        (asserts! (is-valid-power power) ERR-INVALID-POWER)
        (asserts! (not (is-citizen address)) ERR-DUPLICATE-VOTE)
        
        (if (is-eq (get-power address) u0)
            (var-set citizen-count (+ (var-get citizen-count) u1))
            true
        )
        
        (ok (map-set citizen-power address power))
    )
)

(define-public (update-power (address principal) (new-power uint))
    (begin
        (asserts! (is-eq tx-sender (var-get hive-admin)) ERR-UNAUTHORIZED)
        (asserts! (is-valid-power new-power) ERR-INVALID-POWER)
        (asserts! (is-citizen address) ERR-UNAUTHORIZED)
        
        (ok (map-set citizen-power address new-power))
    )
)

(define-public (propose-motion (title (string-ascii 50)) 
                             (details (string-ascii 500)) 
                             (value uint)
                             (target principal))
    (let (
        (motion-id (+ (var-get motion-count) u1))
    )
        (asserts! (is-citizen tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-valid-title title) ERR-BAD-TITLE)
        (asserts! (is-valid-details details) ERR-BAD-DETAILS)
        (asserts! (is-valid-value value) ERR-BAD-VALUE)
        (asserts! (is-valid-target target) ERR-BAD-TARGET)
        
        (asserts! (>= (stx-get-balance (as-contract tx-sender)) value) ERR-LOW-BALANCE)
        
        (map-set motions motion-id {
            initiator: tx-sender,
            title: title,
            details: details,
            value: value,
            target: target,
            start-block: block-height,
            support: u0,
            oppose: u0,
            completed: false
        })
        
        (var-set motion-count motion-id)
        (ok motion-id)
    )
)

(define-public (cast-vote (motion-id uint) (support bool))
    (let (
        (motion (unwrap! (get-motion motion-id) ERR-MOTION-NOT-FOUND))
        (voter-power (get-power tx-sender))
    )
        (asserts! (is-citizen tx-sender) ERR-UNAUTHORIZED)
        (asserts! (> voter-power u0) ERR-INVALID-POWER)
        (asserts! (check-motion-active motion-id) ERR-MOTION-TIMEOUT)
        (asserts! (not (has-cast-vote motion-id tx-sender)) ERR-DUPLICATE-VOTE)
        
        (map-set ballot-box {motion-id: motion-id, citizen: tx-sender} true)
        
        (if support
            (map-set motions motion-id 
                (merge motion {support: (+ (get support motion) voter-power)}))
            (map-set motions motion-id 
                (merge motion {oppose: (+ (get oppose motion) voter-power)}))
        )
        (ok true)
    )
)

(define-public (complete-motion (motion-id uint))
    (let (
        (motion (unwrap! (get-motion motion-id) ERR-MOTION-NOT-FOUND))
    )
        (asserts! (check-motion-active motion-id) ERR-MOTION-TIMEOUT)
        (asserts! (> (get support motion) (get oppose motion)) ERR-UNAUTHORIZED)
        
        (asserts! (>= (stx-get-balance (as-contract tx-sender)) (get value motion)) ERR-LOW-BALANCE)
        
        (try! (as-contract (stx-transfer? 
            (get value motion) 
            tx-sender 
            (get target motion))))
        
        (map-set motions motion-id 
            (merge motion {completed: true}))
        
        (ok true)
    )
)

(define-public (stake-funds (amount uint) (vault-contract <staking-vault-trait>))
    (begin
        (asserts! (is-eq tx-sender (var-get hive-admin)) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-ZERO-VALUE)
        (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount) ERR-LOW-BALANCE)
        
        (try! (as-contract (contract-call? vault-contract stake amount)))
        (ok true)
    )
)

(define-public (unstake-funds (amount uint) (vault-contract <staking-vault-trait>))
    (begin
        (asserts! (is-eq tx-sender (var-get hive-admin)) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-ZERO-VALUE)
        
        (try! (as-contract (contract-call? vault-contract unstake amount)))
        (ok true)
    )
)

(define-public (transfer-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get hive-admin)) ERR-UNAUTHORIZED)
        (asserts! (not (is-eq new-admin (var-get hive-admin))) ERR-BAD-TARGET)
        
        (var-set hive-admin new-admin)
        (ok true)
    )
)