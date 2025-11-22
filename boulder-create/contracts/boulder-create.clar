;; Boulder Create - Decentralized Creator Economy Platform
;; Automated micro-royalty streams and collaborative IP ownership

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-WORK-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-PERCENTAGE (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-INVALID-CONTRIBUTOR (err u105))
(define-constant ERR-WORK-NOT-PUBLISHED (err u106))
(define-constant ERR-INVALID-PRICE (err u107))
(define-constant ERR-INVALID-STAKE (err u108))
(define-constant ERR-LICENSE-NOT-FOUND (err u109))
(define-constant ERR-COMMISSION-NOT-FOUND (err u110))
(define-constant ERR-INVALID-STATUS (err u111))

;; Platform fee percentage (1% = 100 basis points)
(define-constant PLATFORM-FEE u100)
(define-constant BASIS-POINTS u10000)

;; Data Variables
(define-data-var work-counter uint u0)
(define-data-var license-counter uint u0)
(define-data-var commission-counter uint u0)
(define-data-var total-revenue uint u0)
(define-data-var platform-treasury uint u0)

;; Creative Work Structure with DNA
(define-map creative-works
    { work-id: uint }
    {
        creator: principal,
        title: (string-ascii 100),
        content-hash: (buff 32),
        parent-work: (optional uint),
        created-at: uint,
        published: bool,
        total-revenue: uint,
        usage-count: uint,
        price-per-use: uint,
        category: (string-ascii 50)
    }
)

;; Contributor Shares for Multi-Creator Projects
(define-map work-contributors
    { work-id: uint, contributor: principal }
    {
        share-percentage: uint,
        role: (string-ascii 50),
        added-at: uint
    }
)

;; Fractional Ownership Stakes
(define-map ownership-stakes
    { work-id: uint, stakeholder: principal }
    {
        stake-percentage: uint,
        invested-amount: uint,
        purchased-at: uint
    }
)

;; License Records
(define-map licenses
    { license-id: uint }
    {
        work-id: uint,
        licensee: principal,
        license-type: (string-ascii 50),
        price: uint,
        granted-at: uint,
        expires-at: (optional uint),
        active: bool
    }
)

;; Commission/Escrow for Commissioned Works
(define-map commissions
    { commission-id: uint }
    {
        commissioner: principal,
        creator: principal,
        description: (string-ascii 200),
        escrow-amount: uint,
        deadline: uint,
        status: (string-ascii 20),
        created-at: uint,
        completed-work: (optional uint)
    }
)

;; Creator Profiles
(define-map creator-profiles
    { creator: principal }
    {
        total-works: uint,
        total-earnings: uint,
        reputation-score: uint,
        joined-at: uint
    }
)

;; Derivative Work Tracking (Inspiration Graph)
(define-map derivative-relationships
    { parent-id: uint, derivative-id: uint }
    {
        derivative-percentage: uint,
        acknowledged: bool,
        created-at: uint
    }
)

;; Revenue Distribution Events
(define-map revenue-distributions
    { work-id: uint, distribution-id: uint }
    {
        amount: uint,
        distributed-at: uint,
        source: (string-ascii 50)
    }
)

;; Read-only functions

;; Get creative work details
(define-read-only (get-work (work-id uint))
    (map-get? creative-works { work-id: work-id })
)

;; Get contributor share
(define-read-only (get-contributor-share (work-id uint) (contributor principal))
    (map-get? work-contributors { work-id: work-id, contributor: contributor })
)

;; Get ownership stake
(define-read-only (get-stake (work-id uint) (stakeholder principal))
    (map-get? ownership-stakes { work-id: work-id, stakeholder: stakeholder })
)

;; Get license details
(define-read-only (get-license (license-id uint))
    (map-get? licenses { license-id: license-id })
)

;; Get commission details
(define-read-only (get-commission (commission-id uint))
    (map-get? commissions { commission-id: commission-id })
)

;; Get creator profile
(define-read-only (get-creator-profile (creator principal))
    (map-get? creator-profiles { creator: creator })
)

;; Get derivative relationship
(define-read-only (get-derivative-relationship (parent-id uint) (derivative-id uint))
    (map-get? derivative-relationships { parent-id: parent-id, derivative-id: derivative-id })
)

;; Get platform statistics
(define-read-only (get-platform-stats)
    {
        total-works: (var-get work-counter),
        total-licenses: (var-get license-counter),
        total-commissions: (var-get commission-counter),
        total-revenue: (var-get total-revenue),
        platform-treasury: (var-get platform-treasury)
    }
)

;; Public functions

;; Initialize creator profile
(define-public (initialize-creator)
    (let
        (
            (existing-profile (get-creator-profile tx-sender))
        )
        (if (is-some existing-profile)
            ERR-ALREADY-EXISTS
            (begin
                (map-set creator-profiles
                    { creator: tx-sender }
                    {
                        total-works: u0,
                        total-earnings: u0,
                        reputation-score: u100,
                        joined-at: block-height
                    }
                )
                (ok true)
            )
        )
    )
)

;; Register a new creative work
(define-public (register-work
    (title (string-ascii 100))
    (content-hash (buff 32))
    (parent-work (optional uint))
    (category (string-ascii 50))
    (price-per-use uint)
)
    (let
        (
            (work-id (+ (var-get work-counter) u1))
            (creator-profile (unwrap! (get-creator-profile tx-sender) ERR-NOT-AUTHORIZED))
        )
        ;; Create the work
        (map-set creative-works
            { work-id: work-id }
            {
                creator: tx-sender,
                title: title,
                content-hash: content-hash,
                parent-work: parent-work,
                created-at: block-height,
                published: false,
                total-revenue: u0,
                usage-count: u0,
                price-per-use: price-per-use,
                category: category
            }
        )

        ;; Add creator as 100% contributor initially
        (map-set work-contributors
            { work-id: work-id, contributor: tx-sender }
            {
                share-percentage: u10000,
                role: "creator",
                added-at: block-height
            }
        )

        ;; Update creator profile
        (map-set creator-profiles
            { creator: tx-sender }
            (merge creator-profile {
                total-works: (+ (get total-works creator-profile) u1)
            })
        )

        ;; If derivative work, track relationship
        (match parent-work
            parent-id
            (map-set derivative-relationships
                { parent-id: parent-id, derivative-id: work-id }
                {
                    derivative-percentage: u2000, ;; 20% default to parent
                    acknowledged: false,
                    created-at: block-height
                }
            )
            true
        )

        (var-set work-counter work-id)

        (ok work-id)
    )
)

;; Add contributor to work
(define-public (add-contributor
    (work-id uint)
    (contributor principal)
    (share-percentage uint)
    (role (string-ascii 50))
)
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
            (creator-share (unwrap! (get-contributor-share work-id (get creator work)) ERR-INVALID-CONTRIBUTOR))
        )
        ;; Only creator can add contributors
        (asserts! (is-eq tx-sender (get creator work)) ERR-NOT-AUTHORIZED)

        ;; Validate percentage
        (asserts! (<= share-percentage u10000) ERR-INVALID-PERCENTAGE)

        ;; Reduce creator's share
        (asserts! (>= (get share-percentage creator-share) share-percentage) ERR-INVALID-PERCENTAGE)

        ;; Add contributor
        (map-set work-contributors
            { work-id: work-id, contributor: contributor }
            {
                share-percentage: share-percentage,
                role: role,
                added-at: block-height
            }
        )

        ;; Update creator's share
        (map-set work-contributors
            { work-id: work-id, contributor: (get creator work) }
            (merge creator-share {
                share-percentage: (- (get share-percentage creator-share) share-percentage)
            })
        )

        (ok true)
    )
)

;; Publish work to marketplace
(define-public (publish-work (work-id uint))
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
        )
        ;; Only creator can publish
        (asserts! (is-eq tx-sender (get creator work)) ERR-NOT-AUTHORIZED)

        ;; Mark as published
        (map-set creative-works
            { work-id: work-id }
            (merge work { published: true })
        )

        (ok true)
    )
)

;; Purchase fractional ownership stake
(define-public (purchase-stake (work-id uint) (stake-percentage uint))
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
            (investment-amount (* (/ (* stake-percentage u1000000) u10000) u1)) ;; Simplified pricing
        )
        ;; Validate stake percentage
        (asserts! (and (> stake-percentage u0) (<= stake-percentage u5000)) ERR-INVALID-STAKE)

        ;; Work must be published
        (asserts! (get published work) ERR-WORK-NOT-PUBLISHED)

        ;; Record stake
        (map-set ownership-stakes
            { work-id: work-id, stakeholder: tx-sender }
            {
                stake-percentage: stake-percentage,
                invested-amount: investment-amount,
                purchased-at: block-height
            }
        )

        (ok true)
    )
)

;; Grant license to use work
(define-public (grant-license
    (work-id uint)
    (licensee principal)
    (license-type (string-ascii 50))
    (price uint)
    (expires-at (optional uint))
)
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
            (license-id (+ (var-get license-counter) u1))
        )
        ;; Only creator can grant licenses
        (asserts! (is-eq tx-sender (get creator work)) ERR-NOT-AUTHORIZED)

        ;; Work must be published
        (asserts! (get published work) ERR-WORK-NOT-PUBLISHED)

        ;; Create license
        (map-set licenses
            { license-id: license-id }
            {
                work-id: work-id,
                licensee: licensee,
                license-type: license-type,
                price: price,
                granted-at: block-height,
                expires-at: expires-at,
                active: true
            }
        )

        (var-set license-counter license-id)

        ;; Distribute payment if price > 0
        (if (> price u0)
            (try! (distribute-revenue work-id price "license"))
            true
        )

        (ok license-id)
    )
)

;; Create commission for work
(define-public (create-commission
    (creator principal)
    (description (string-ascii 200))
    (escrow-amount uint)
    (deadline uint)
)
    (let
        (
            (commission-id (+ (var-get commission-counter) u1))
        )
        ;; Validate escrow amount
        (asserts! (> escrow-amount u0) ERR-INVALID-PRICE)

        ;; Create commission
        (map-set commissions
            { commission-id: commission-id }
            {
                commissioner: tx-sender,
                creator: creator,
                description: description,
                escrow-amount: escrow-amount,
                deadline: deadline,
                status: "pending",
                created-at: block-height,
                completed-work: none
            }
        )

        (var-set commission-counter commission-id)

        (ok commission-id)
    )
)

;; Complete commission
(define-public (complete-commission (commission-id uint) (work-id uint))
    (let
        (
            (commission (unwrap! (get-commission commission-id) ERR-COMMISSION-NOT-FOUND))
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
        )
        ;; Only assigned creator can complete
        (asserts! (is-eq tx-sender (get creator commission)) ERR-NOT-AUTHORIZED)

        ;; Must be pending
        (asserts! (is-eq (get status commission) "pending") ERR-INVALID-STATUS)

        ;; Creator must own the work
        (asserts! (is-eq tx-sender (get creator work)) ERR-NOT-AUTHORIZED)

        ;; Update commission
        (map-set commissions
            { commission-id: commission-id }
            (merge commission {
                status: "completed",
                completed-work: (some work-id)
            })
        )

        ;; Distribute escrow to creator
        (try! (distribute-revenue work-id (get escrow-amount commission) "commission"))

        (ok true)
    )
)

;; Record revenue from usage
(define-public (record-usage (work-id uint))
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
            (price (get price-per-use work))
        )
        ;; Work must be published
        (asserts! (get published work) ERR-WORK-NOT-PUBLISHED)

        ;; Update usage count
        (map-set creative-works
            { work-id: work-id }
            (merge work {
                usage-count: (+ (get usage-count work) u1)
            })
        )

        ;; Distribute revenue
        (if (> price u0)
            (try! (distribute-revenue work-id price "usage"))
            true
        )

        (ok true)
    )
)

;; Distribute revenue to contributors and stakeholders
(define-public (distribute-revenue (work-id uint) (amount uint) (source (string-ascii 50)))
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
            (platform-cut (/ (* amount PLATFORM-FEE) BASIS-POINTS))
            (distributable (- amount platform-cut))
        )
        ;; Update platform treasury
        (var-set platform-treasury (+ (var-get platform-treasury) platform-cut))

        ;; Update total revenue
        (var-set total-revenue (+ (var-get total-revenue) amount))

        ;; Update work revenue
        (map-set creative-works
            { work-id: work-id }
            (merge work {
                total-revenue: (+ (get total-revenue work) amount)
            })
        )

        ;; If derivative work, distribute to parent
        (match (get parent-work work)
            parent-id
            (let
                (
                    (relationship (unwrap! (get-derivative-relationship parent-id work-id) ERR-WORK-NOT-FOUND))
                    (parent-share (/ (* distributable (get derivative-percentage relationship)) BASIS-POINTS))
                )
                ;; Recursively distribute to parent
                (try! (distribute-to-contributors parent-id parent-share))
                ;; Distribute remaining to current work contributors
                (try! (distribute-to-contributors work-id (- distributable parent-share)))
            )
            ;; No parent, distribute full amount
            (try! (distribute-to-contributors work-id distributable))
        )

        (ok true)
    )
)

;; Helper: Distribute to contributors
(define-private (distribute-to-contributors (work-id uint) (amount uint))
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
            (creator (get creator work))
            (creator-share (unwrap! (get-contributor-share work-id creator) ERR-INVALID-CONTRIBUTOR))
            (creator-amount (/ (* amount (get share-percentage creator-share)) BASIS-POINTS))
            (creator-profile (unwrap! (get-creator-profile creator) ERR-NOT-AUTHORIZED))
        )
        ;; Update creator earnings
        (map-set creator-profiles
            { creator: creator }
            (merge creator-profile {
                total-earnings: (+ (get total-earnings creator-profile) creator-amount)
            })
        )

        (ok true)
    )
)

;; Acknowledge derivative relationship
(define-public (acknowledge-derivative (parent-id uint) (derivative-id uint))
    (let
        (
            (parent-work (unwrap! (get-work parent-id) ERR-WORK-NOT-FOUND))
            (relationship (unwrap! (get-derivative-relationship parent-id derivative-id) ERR-WORK-NOT-FOUND))
        )
        ;; Only parent creator can acknowledge
        (asserts! (is-eq tx-sender (get creator parent-work)) ERR-NOT-AUTHORIZED)

        ;; Mark as acknowledged
        (map-set derivative-relationships
            { parent-id: parent-id, derivative-id: derivative-id }
            (merge relationship { acknowledged: true })
        )

        (ok true)
    )
)

;; Update work price
(define-public (update-price (work-id uint) (new-price uint))
    (let
        (
            (work (unwrap! (get-work work-id) ERR-WORK-NOT-FOUND))
        )
        ;; Only creator can update price
        (asserts! (is-eq tx-sender (get creator work)) ERR-NOT-AUTHORIZED)

        ;; Update price
        (map-set creative-works
            { work-id: work-id }
            (merge work { price-per-use: new-price })
        )

        (ok true)
    )
)
