;; Agriculture Supply Chain Management Contract
;; Implements tracking, quality control, and stakeholder management

;; Constants
(define-constant contract-administrator tx-sender)
(define-constant ERROR-UNAUTHORIZED-ACCESS (err u1))
(define-constant ERROR-PRODUCT-NOT-FOUND (err u2))
(define-constant ERROR-INVALID-STATUS-UPDATE (err u3))
(define-constant ERROR-DUPLICATE-ENTRY (err u4))

;; Data Variables
(define-data-var minimum-quality-threshold uint u60)

;; Principal Maps
(define-map supply-chain-participants
    principal
    {
        participant-role: (string-ascii 20),
        is-active: bool,
        participant-reputation: uint
    }
)

;; Product Structure
(define-map agricultural-products
    uint  ;; product-identifier
    {
        product-name: (string-ascii 50),
        producer-principal: principal,
        current-custodian: principal,
        product-status: (string-ascii 20),
        product-quality-rating: uint,
        registration-timestamp: uint,
        current-location: (string-ascii 100),
        market-price: uint,
        quality-certified: bool
    }
)

;; Transaction History
(define-map supply-chain-transactions
    {product-identifier: uint, transaction-identifier: uint}
    {
        sender-principal: principal,
        receiver-principal: principal,
        transaction-type: (string-ascii 20),
        transaction-timestamp: uint,
        transaction-notes: (string-ascii 200)
    }
)

;; Counter for transaction IDs
(define-data-var transaction-counter uint u0)

;; Read-only functions
(define-read-only (get-agricultural-product-details (product-identifier uint))
    (map-get? agricultural-products product-identifier)
)

(define-read-only (get-participant-details (participant-principal principal))
    (map-get? supply-chain-participants participant-principal)
)

(define-read-only (get-supply-chain-transaction (product-identifier uint) (transaction-identifier uint))
    (map-get? supply-chain-transactions {product-identifier: product-identifier, transaction-identifier: transaction-identifier})
)

;; Internal Functions
(define-private (is-participant-authorized (participant-principal principal))
    (let ((participant-info (unwrap! (map-get? supply-chain-participants participant-principal) false)))
        (get is-active participant-info)
    )
)

(define-private (increment-transaction-counter)
    (begin
        (var-set transaction-counter (+ (var-get transaction-counter) u1))
        (var-get transaction-counter)
    )
)

;; Administrative Functions
(define-public (register-supply-chain-participant (participant-principal principal) (participant-role (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-none (map-get? supply-chain-participants participant-principal)) ERROR-DUPLICATE-ENTRY)
        (ok (map-set supply-chain-participants 
            participant-principal
            {
                participant-role: participant-role,
                is-active: true,
                participant-reputation: u100
            }
        ))
    )
)

(define-public (update-participant-status (participant-principal principal) (is-active bool))
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-some (map-get? supply-chain-participants participant-principal)) ERROR-UNAUTHORIZED-ACCESS)
        (ok (map-set supply-chain-participants 
            participant-principal
            (merge (unwrap-panic (map-get? supply-chain-participants participant-principal))
                  {is-active: is-active})
        ))
    )
)

;; Product Management Functions
(define-public (register-agricultural-product 
    (product-identifier uint)
    (product-name (string-ascii 50))
    (product-location (string-ascii 100))
    (product-price uint))
    (let ((requesting-participant tx-sender))
        (begin
            (asserts! (is-participant-authorized requesting-participant) ERROR-UNAUTHORIZED-ACCESS)
            (asserts! (is-none (map-get? agricultural-products product-identifier)) ERROR-DUPLICATE-ENTRY)
            (ok (map-set agricultural-products
                product-identifier
                {
                    product-name: product-name,
                    producer-principal: requesting-participant,
                    current-custodian: requesting-participant,
                    product-status: "registered",
                    product-quality-rating: u100,
                    registration-timestamp: block-height,
                    current-location: product-location,
                    market-price: product-price,
                    quality-certified: false
                }
            ))
        )
    )
)

(define-public (update-product-status 
    (product-identifier uint)
    (updated-status (string-ascii 20))
    (status-notes (string-ascii 200)))
    (let (
        (requesting-participant tx-sender)
        (product-info (unwrap! (map-get? agricultural-products product-identifier) ERROR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-participant-authorized requesting-participant) ERROR-UNAUTHORIZED-ACCESS)
            (asserts! (is-eq (get current-custodian product-info) requesting-participant) ERROR-UNAUTHORIZED-ACCESS)
            (map-set agricultural-products
                product-identifier
                (merge product-info {product-status: updated-status})
            )
            (map-set supply-chain-transactions
                {product-identifier: product-identifier, transaction-identifier: (increment-transaction-counter)}
                {
                    sender-principal: requesting-participant,
                    receiver-principal: requesting-participant,
                    transaction-type: updated-status,
                    transaction-timestamp: block-height,
                    transaction-notes: status-notes
                }
            )
            (ok true)
        )
    )
)

(define-public (transfer-product-ownership
    (product-identifier uint)
    (new-custodian principal)
    (transfer-notes (string-ascii 200)))
    (let (
        (current-custodian tx-sender)
        (product-info (unwrap! (map-get? agricultural-products product-identifier) ERROR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-participant-authorized current-custodian) ERROR-UNAUTHORIZED-ACCESS)
            (asserts! (is-participant-authorized new-custodian) ERROR-UNAUTHORIZED-ACCESS)
            (asserts! (is-eq (get current-custodian product-info) current-custodian) ERROR-UNAUTHORIZED-ACCESS)
            (map-set agricultural-products
                product-identifier
                (merge product-info {
                    current-custodian: new-custodian,
                    product-status: "transferred"
                })
            )
            (map-set supply-chain-transactions
                {product-identifier: product-identifier, transaction-identifier: (increment-transaction-counter)}
                {
                    sender-principal: current-custodian,
                    receiver-principal: new-custodian,
                    transaction-type: "transfer",
                    transaction-timestamp: block-height,
                    transaction-notes: transfer-notes
                }
            )
            (ok true)
        )
    )
)

(define-public (update-product-quality
    (product-identifier uint)
    (updated-quality-score uint)
    (quality-notes (string-ascii 200)))
    (let (
        (quality-assessor tx-sender)
        (product-info (unwrap! (map-get? agricultural-products product-identifier) ERROR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-participant-authorized quality-assessor) ERROR-UNAUTHORIZED-ACCESS)
            (asserts! (<= updated-quality-score u100) ERROR-PRODUCT-NOT-FOUND)
            (map-set agricultural-products
                product-identifier
                (merge product-info {
                    product-quality-rating: updated-quality-score,
                    quality-certified: (>= updated-quality-score (var-get minimum-quality-threshold))
                })
            )
            (map-set supply-chain-transactions
                {product-identifier: product-identifier, transaction-identifier: (increment-transaction-counter)}
                {
                    sender-principal: quality-assessor,
                    receiver-principal: quality-assessor,
                    transaction-type: "quality-update",
                    transaction-timestamp: block-height,
                    transaction-notes: quality-notes
                }
            )
            (ok true)
        )
    )
)

(define-public (update-product-location
    (product-identifier uint)
    (updated-location (string-ascii 100))
    (location-notes (string-ascii 200)))
    (let (
        (requesting-participant tx-sender)
        (product-info (unwrap! (map-get? agricultural-products product-identifier) ERROR-PRODUCT-NOT-FOUND))
        )
        (begin
            (asserts! (is-participant-authorized requesting-participant) ERROR-UNAUTHORIZED-ACCESS)
            (asserts! (is-eq (get current-custodian product-info) requesting-participant) ERROR-UNAUTHORIZED-ACCESS)
            (map-set agricultural-products
                product-identifier
                (merge product-info {current-location: updated-location})
            )
            (map-set supply-chain-transactions
                {product-identifier: product-identifier, transaction-identifier: (increment-transaction-counter)}
                {
                    sender-principal: requesting-participant,
                    receiver-principal: requesting-participant,
                    transaction-type: "location-update",
                    transaction-timestamp: block-height,
                    transaction-notes: location-notes
                }
            )
            (ok true)
        )
    )
)