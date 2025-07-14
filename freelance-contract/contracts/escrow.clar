;; Enhanced Escrow Contract for Freelance Work
;; Fixes bugs and adds security features

;; Error constants
(define-constant err-not-client (err u100))
(define-constant err-not-freelancer (err u101))
(define-constant err-not-funded (err u102))
(define-constant err-already-released (err u103))
(define-constant err-insufficient-amount (err u104))
(define-constant err-invalid-freelancer (err u105))
(define-constant err-already-funded (err u106))
(define-constant err-deadline-passed (err u107))
(define-constant err-deadline-not-reached (err u108))

;; Data variables
(define-data-var client principal tx-sender)
(define-data-var freelancer principal 'SP000000000000000000002Q6VF78)
(define-data-var amount uint u0)
(define-data-var funded bool false)
(define-data-var released bool false)
(define-data-var deadline uint u0)
(define-data-var dispute-raised bool false)
(define-data-var work-completed bool false)

;; Maps for tracking project details
(define-map project-details
  { project-id: uint }
  {
    description: (string-ascii 256),
    milestones: uint,
    completed-milestones: uint,
    created-at: uint
  }
)

;; Current project counter
(define-data-var project-counter uint u0)

;; Read-only functions
(define-read-only (get-client)
  (var-get client)
)

(define-read-only (get-freelancer)
  (var-get freelancer)
)

(define-read-only (get-amount)
  (var-get amount)
)

(define-read-only (is-funded)
  (var-get funded)
)

(define-read-only (is-released)
  (var-get released)
)

(define-read-only (get-deadline)
  (var-get deadline)
)

(define-read-only (is-work-completed)
  (var-get work-completed)
)

(define-read-only (get-project-details (project-id uint))
  (map-get? project-details { project-id: project-id })
)

;; Public functions

;; Initialize contract with project details
(define-public (initialize-project (freelancer-address principal) (project-amount uint) (deadline-block uint) (description (string-ascii 256)) (total-milestones uint))
  (begin
    (asserts! (is-eq tx-sender (var-get client)) err-not-client)
    (asserts! (> project-amount u0) err-insufficient-amount)
    (asserts! (> deadline-block block-height) err-deadline-passed)
    (asserts! (not (is-eq freelancer-address (var-get client))) err-invalid-freelancer)
    (asserts! (not (var-get funded)) err-already-funded)
    ;; Validate description is not empty
    (asserts! (> (len description) u0) err-insufficient-amount)
    ;; Validate milestones count
    (asserts! (and (> total-milestones u0) (<= total-milestones u100)) err-insufficient-amount)
    
    ;; Set project variables
    (var-set freelancer freelancer-address)
    (var-set amount project-amount)
    (var-set deadline deadline-block)
    
    ;; Create project record with validated inputs
    (let ((current-id (+ (var-get project-counter) u1))
          (validated-description (if (> (len description) u0) description "Default project"))
          (validated-milestones (if (and (> total-milestones u0) (<= total-milestones u100)) total-milestones u1)))
      (var-set project-counter current-id)
      (map-set project-details
        { project-id: current-id }
        {
          description: validated-description,
          milestones: validated-milestones,
          completed-milestones: u0,
          created-at: block-height
        }
      )
    )
    
    (ok true)
  )
)

;; Fund the escrow
(define-public (fund-escrow)
  (begin
    (asserts! (is-eq tx-sender (var-get client)) err-not-client)
    (asserts! (not (var-get funded)) err-already-funded)
    (asserts! (> (var-get amount) u0) err-insufficient-amount)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? (var-get amount) tx-sender (as-contract tx-sender)))
    (var-set funded true)
    (ok true)
  )
)

;; Mark milestone as completed (freelancer function)
(define-public (complete-milestone (project-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get freelancer)) err-not-freelancer)
    (asserts! (var-get funded) err-not-funded)
    (asserts! (< block-height (var-get deadline)) err-deadline-passed)
    ;; Validate project-id
    (asserts! (> project-id u0) err-insufficient-amount)
    
    (match (map-get? project-details { project-id: project-id })
      project-data
      (let ((completed (+ (get completed-milestones project-data) u1)))
        (asserts! (<= completed (get milestones project-data)) err-insufficient-amount)
        (map-set project-details
          { project-id: project-id }
          (merge project-data { completed-milestones: completed })
        )
        ;; Check if all milestones are completed
        (if (is-eq completed (get milestones project-data))
          (var-set work-completed true)
          true
        )
        (ok completed)
      )
      err-insufficient-amount ;; Project not found
    )
  )
)

;; Release funds (client function)
(define-public (release-funds)
  (begin
    (asserts! (is-eq tx-sender (var-get client)) err-not-client)
    (asserts! (var-get funded) err-not-funded)
    (asserts! (not (var-get released)) err-already-released)
    (asserts! (var-get work-completed) err-insufficient-amount)
    
    ;; Transfer funds to freelancer
    (try! (as-contract (stx-transfer? (var-get amount) tx-sender (var-get freelancer))))
    (var-set released true)
    (ok true)
  )
)

;; Emergency release after deadline (freelancer function)
(define-public (emergency-release)
  (begin
    (asserts! (is-eq tx-sender (var-get freelancer)) err-not-freelancer)
    (asserts! (var-get funded) err-not-funded)
    (asserts! (not (var-get released)) err-already-released)
    (asserts! (>= block-height (var-get deadline)) err-deadline-not-reached)
    
    ;; Transfer funds to freelancer after deadline
    (try! (as-contract (stx-transfer? (var-get amount) tx-sender (var-get freelancer))))
    (var-set released true)
    (ok true)
  )
)

;; Raise dispute (both parties can call this)
(define-public (raise-dispute)
  (begin
    (asserts! (or (is-eq tx-sender (var-get client)) (is-eq tx-sender (var-get freelancer))) err-not-client)
    (asserts! (var-get funded) err-not-funded)
    (asserts! (not (var-get released)) err-already-released)
    
    (var-set dispute-raised true)
    (ok true)
  )
)

;; Cancel contract and refund (only if not funded or work not started)
(define-public (cancel-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get client)) err-not-client)
    (asserts! (var-get funded) err-not-funded)
    (asserts! (not (var-get released)) err-already-released)
    (asserts! (not (var-get work-completed)) err-insufficient-amount)
    
    ;; Refund client
    (try! (as-contract (stx-transfer? (var-get amount) tx-sender (var-get client))))
    (var-set released true)
    (ok true)
  )
)
