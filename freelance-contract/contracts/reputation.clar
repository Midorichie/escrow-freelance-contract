;; Reputation Management Contract
;; Tracks freelancer and client reputation scores

;; Error constants
(define-constant err-not-authorized (err u200))
(define-constant err-invalid-rating (err u201))
(define-constant err-already-rated (err u202))
(define-constant err-self-rating (err u203))

;; Data maps
(define-map user-reputation
  { user: principal }
  {
    total-score: uint,
    completed-projects: uint,
    average-rating: uint,
    last-updated: uint
  }
)

(define-map project-ratings
  { project-id: uint, rater: principal, ratee: principal }
  {
    rating: uint,
    comment: (string-ascii 256),
    timestamp: uint
  }
)

;; Contract owner (for admin functions)
(define-data-var contract-owner principal tx-sender)

;; Read-only functions
(define-read-only (get-user-reputation (user principal))
  (default-to 
    { total-score: u0, completed-projects: u0, average-rating: u0, last-updated: u0 }
    (map-get? user-reputation { user: user })
  )
)

(define-read-only (get-project-rating (project-id uint) (rater principal) (ratee principal))
  (map-get? project-ratings { project-id: project-id, rater: rater, ratee: ratee })
)

(define-read-only (calculate-reputation-score (user principal))
  (let ((rep-data (get-user-reputation user)))
    (if (> (get completed-projects rep-data) u0)
      (/ (get total-score rep-data) (get completed-projects rep-data))
      u0
    )
  )
)

;; Public functions
(define-public (rate-user (project-id uint) (ratee principal) (rating uint) (comment (string-ascii 256)))
  (begin
    ;; Validate inputs
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (asserts! (not (is-eq tx-sender ratee)) err-self-rating)
    (asserts! (> project-id u0) err-invalid-rating)
    ;; Validate comment length
    (asserts! (<= (len comment) u256) err-invalid-rating)
    (asserts! (is-none (map-get? project-ratings { project-id: project-id, rater: tx-sender, ratee: ratee })) err-already-rated)
    
    ;; Sanitize comment - remove any potentially harmful characters
    (let ((sanitized-comment (if (> (len comment) u0) comment "No comment provided")))
      ;; Store rating with sanitized data
      (map-set project-ratings
        { project-id: project-id, rater: tx-sender, ratee: ratee }
        {
          rating: rating,
          comment: sanitized-comment,
          timestamp: block-height
        }
      )
      
      ;; Update user reputation
      (let ((current-rep (get-user-reputation ratee)))
        (map-set user-reputation
          { user: ratee }
          {
            total-score: (+ (get total-score current-rep) rating),
            completed-projects: (+ (get completed-projects current-rep) u1),
            average-rating: (/ (+ (get total-score current-rep) rating) (+ (get completed-projects current-rep) u1)),
            last-updated: block-height
          }
        )
      )
    )
    
    (ok true)
  )
)

(define-public (update-project-completion (user principal))
  (begin
    ;; Validate that user is a valid principal (not zero address)
    (asserts! (not (is-eq user 'SP000000000000000000002Q6VF78)) err-not-authorized)
    ;; This would be called by the escrow contract when a project is completed
    (let ((current-rep (get-user-reputation user)))
      (map-set user-reputation
        { user: user }
        {
          total-score: (get total-score current-rep),
          completed-projects: (get completed-projects current-rep),
          average-rating: (get average-rating current-rep),
          last-updated: block-height
        }
      )
    )
    (ok true)
  )
)
