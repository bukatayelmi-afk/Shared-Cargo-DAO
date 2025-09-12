(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_SPACE_NOT_AVAILABLE (err u105))
(define-constant ERR_BOOKING_NOT_FOUND (err u106))
(define-constant ERR_BOOKING_EXPIRED (err u107))
(define-constant ERR_INVALID_RATING (err u108))

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var platform-fee uint u250)
(define-data-var next-business-id uint u1)
(define-data-var next-cargo-space-id uint u1)
(define-data-var next-booking-id uint u1)

(define-map businesses
    uint
    {
        owner: principal,
        name: (string-ascii 64),
        location: (string-ascii 128),
        reputation-score: uint,
        total-ratings: uint,
        active: bool,
        created-at: uint
    }
)

(define-map business-owners principal uint)

(define-map cargo-spaces
    uint
    {
        business-id: uint,
        space-type: (string-ascii 32),
        capacity: uint,
        price-per-kg: uint,
        available: bool,
        from-location: (string-ascii 128),
        to-location: (string-ascii 128),
        departure-date: uint,
        arrival-date: uint,
        created-at: uint
    }
)

(define-map bookings
    uint
    {
        cargo-space-id: uint,
        buyer: principal,
        weight: uint,
        total-cost: uint,
        status: (string-ascii 16),
        booked-at: uint,
        completed-at: (optional uint)
    }
)

(define-map user-ratings
    { rater: principal, business-id: uint }
    { rating: uint, comment: (string-ascii 256), rated-at: uint }
)

(define-public (register-business (name (string-ascii 64)) (location (string-ascii 128)))
    (let
        (
            (business-id (var-get next-business-id))
            (existing-business (map-get? business-owners tx-sender))
        )
        (asserts! (is-none existing-business) ERR_ALREADY_EXISTS)
        (map-set businesses business-id
            {
                owner: tx-sender,
                name: name,
                location: location,
                reputation-score: u0,
                total-ratings: u0,
                active: true,
                created-at: stacks-block-height
            }
        )
        (map-set business-owners tx-sender business-id)
        (var-set next-business-id (+ business-id u1))
        (ok business-id)
    )
)

(define-public (create-cargo-space 
    (space-type (string-ascii 32))
    (capacity uint)
    (price-per-kg uint)
    (from-location (string-ascii 128))
    (to-location (string-ascii 128))
    (departure-date uint)
    (arrival-date uint)
)
    (let
        (
            (business-id (unwrap! (map-get? business-owners tx-sender) ERR_NOT_FOUND))
            (cargo-space-id (var-get next-cargo-space-id))
        )
        (asserts! (> capacity u0) ERR_INVALID_AMOUNT)
        (asserts! (> price-per-kg u0) ERR_INVALID_AMOUNT)
        (asserts! (> departure-date stacks-block-height) ERR_INVALID_AMOUNT)
        (asserts! (> arrival-date departure-date) ERR_INVALID_AMOUNT)
        (map-set cargo-spaces cargo-space-id
            {
                business-id: business-id,
                space-type: space-type,
                capacity: capacity,
                price-per-kg: price-per-kg,
                available: true,
                from-location: from-location,
                to-location: to-location,
                departure-date: departure-date,
                arrival-date: arrival-date,
                created-at: stacks-block-height
            }
        )
        (var-set next-cargo-space-id (+ cargo-space-id u1))
        (ok cargo-space-id)
    )
)

(define-public (book-cargo-space (cargo-space-id uint) (weight uint))
    (let
        (
            (cargo-space (unwrap! (map-get? cargo-spaces cargo-space-id) ERR_NOT_FOUND))
            (business-id (get business-id cargo-space))
            (business (unwrap! (map-get? businesses business-id) ERR_NOT_FOUND))
            (total-cost (* weight (get price-per-kg cargo-space)))
            (platform-fee-amount (/ (* total-cost (var-get platform-fee)) u10000))
            (business-payment (- total-cost platform-fee-amount))
            (booking-id (var-get next-booking-id))
        )
        (asserts! (get available cargo-space) ERR_SPACE_NOT_AVAILABLE)
        (asserts! (>= (get capacity cargo-space) weight) ERR_INVALID_AMOUNT)
        (asserts! (> weight u0) ERR_INVALID_AMOUNT)
        (asserts! (get active business) ERR_NOT_FOUND)
        (asserts! (> (get departure-date cargo-space) stacks-block-height) ERR_BOOKING_EXPIRED)
        
        (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? business-payment tx-sender (get owner business))))
        (try! (as-contract (stx-transfer? platform-fee-amount tx-sender (var-get contract-owner))))
        
        (map-set bookings booking-id
            {
                cargo-space-id: cargo-space-id,
                buyer: tx-sender,
                weight: weight,
                total-cost: total-cost,
                status: "booked",
                booked-at: stacks-block-height,
                completed-at: none
            }
        )
        
        (map-set cargo-spaces cargo-space-id
            (merge cargo-space { capacity: (- (get capacity cargo-space) weight) })
        )
        
        (if (is-eq (get capacity (unwrap-panic (map-get? cargo-spaces cargo-space-id))) u0)
            (map-set cargo-spaces cargo-space-id
                (merge (unwrap-panic (map-get? cargo-spaces cargo-space-id)) { available: false })
            )
            true
        )
        
        (var-set next-booking-id (+ booking-id u1))
        (ok booking-id)
    )
)

(define-public (complete-booking (booking-id uint))
    (let
        (
            (booking (unwrap! (map-get? bookings booking-id) ERR_BOOKING_NOT_FOUND))
            (cargo-space-id (get cargo-space-id booking))
            (cargo-space (unwrap! (map-get? cargo-spaces cargo-space-id) ERR_NOT_FOUND))
            (business-id (get business-id cargo-space))
            (business (unwrap! (map-get? businesses business-id) ERR_NOT_FOUND))
        )
        (asserts! (is-eq tx-sender (get owner business)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status booking) "booked") ERR_BOOKING_NOT_FOUND)
        (map-set bookings booking-id
            (merge booking { 
                status: "completed",
                completed-at: (some stacks-block-height)
            })
        )
        (ok true)
    )
)

(define-public (rate-business (business-id uint) (rating uint) (comment (string-ascii 256)))
    (let
        (
            (business (unwrap! (map-get? businesses business-id) ERR_NOT_FOUND))
            (existing-rating (map-get? user-ratings { rater: tx-sender, business-id: business-id }))
            (current-total (get total-ratings business))
            (current-score (get reputation-score business))
        )
        (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
        (asserts! (is-none existing-rating) ERR_ALREADY_EXISTS)
        
        (map-set user-ratings { rater: tx-sender, business-id: business-id }
            { rating: rating, comment: comment, rated-at: stacks-block-height }
        )
        
        (let
            (
                (new-total (+ current-total u1))
                (new-score (/ (+ (* current-score current-total) rating) new-total))
            )
            (map-set businesses business-id
                (merge business { 
                    reputation-score: new-score,
                    total-ratings: new-total
                })
            )
        )
        (ok true)
    )
)

(define-public (toggle-business-status)
    (let
        (
            (business-id (unwrap! (map-get? business-owners tx-sender) ERR_NOT_FOUND))
            (business (unwrap! (map-get? businesses business-id) ERR_NOT_FOUND))
        )
        (map-set businesses business-id
            (merge business { active: (not (get active business)) })
        )
        (ok (not (get active business)))
    )
)

(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT)
        (var-set platform-fee new-fee)
        (ok true)
    )
)

(define-read-only (get-business (business-id uint))
    (map-get? businesses business-id)
)

(define-read-only (get-cargo-space (cargo-space-id uint))
    (map-get? cargo-spaces cargo-space-id)
)

(define-read-only (get-booking (booking-id uint))
    (map-get? bookings booking-id)
)

(define-read-only (get-business-by-owner (owner principal))
    (match (map-get? business-owners owner)
        business-id (map-get? businesses business-id)
        none
    )
)

(define-read-only (get-user-rating (rater principal) (business-id uint))
    (map-get? user-ratings { rater: rater, business-id: business-id })
)

(define-read-only (get-platform-fee)
    (var-get platform-fee)
)

(define-read-only (get-contract-stats)
    {
        total-businesses: (- (var-get next-business-id) u1),
        total-cargo-spaces: (- (var-get next-cargo-space-id) u1),
        total-bookings: (- (var-get next-booking-id) u1),
        platform-fee: (var-get platform-fee)
    }
)
