;; Event Commitment Contract
;; A decentralized system for tracking and verifying event commitments with optional staking and third-party validation.

;; =======================================
;; Constants and Error Codes
;; =======================================
(define-constant contract-owner tx-sender)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-no-such-commitment (err u101))
(define-constant err-no-such-stage (err u102))
(define-constant err-commitment-already-exists (err u103))
(define-constant err-stage-already-exists (err u104))
(define-constant err-commitment-deadline-passed (err u105))
(define-constant err-commitment-completed (err u106))
(define-constant err-insufficient-stake (err u107))
(define-constant err-not-validator (err u108))
(define-constant err-invalid-privacy-setting (err u109))
(define-constant err-invalid-deadline (err u110))
(define-constant err-stage-already-completed (err u111))
(define-constant err-validation-required (err u112))

;; Privacy settings
(define-constant privacy-public u1)
(define-constant privacy-private u2)

;; =======================================
;; Data Maps and Variables
;; =======================================

;; Maps commitment ID to commitment details
(define-map commitments
  {
    user: principal,
    commitment-id: uint
  }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    deadline: (optional uint),
    created-at: uint,
    completed-at: (optional uint),
    privacy: uint,
    validator: (optional principal),
    stake-amount: uint,
    total-stages: uint,
    completed-stages: uint
  }
)

;; Maps stage ID to stage details
(define-map stages
  {
    user: principal,
    commitment-id: uint,
    stage-id: uint
  }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    completed: bool,
    completed-at: (optional uint),
    validated-by: (optional principal)
  }
)

;; Tracks the next commitment ID for each user
(define-map user-commitment-count principal uint)

;; =======================================
;; Private Functions
;; =======================================


;; Check if user is authorized to modify a goal
(define-private (is-goal-owner (user principal) (commitment-id uint))
  (is-eq tx-sender user)
)

;; Check if user is authorized as a witness for a goal
(define-private (is-goal-witness (user principal) (commitment-id uint))
  (let
    (
      (goal-data (unwrap! (map-get? commitments {user: user, commitment-id: commitment-id}) false))
      (witness (get validator goal-data))
    )
    (and
      (is-some witness)
      (is-eq tx-sender (unwrap! witness false))
    )
  )
)

;; Validate privacy setting
(define-private (validate-privacy (privacy-setting uint))
  (or 
    (is-eq privacy-setting privacy-public)
    (is-eq privacy-setting privacy-private)
  )
)

;; =======================================
;; Read-Only Functions
;; =======================================

;; Get goal details
(define-read-only (get-goal (user principal) (goal-id uint))
  (let
    (
      (goal-data (map-get? commitments {user: user, commitment-id: goal-id}))
    )
    (if (is-some goal-data)
      (let
        (
          (unwrapped-data (unwrap-panic goal-data))
          (privacy (get privacy unwrapped-data))
        )
        (if (or 
              (is-eq privacy privacy-public)
              (is-eq tx-sender user)
              (is-eq tx-sender (default-to contract-owner (get validator unwrapped-data)))
            )
          (ok unwrapped-data)
          (err err-not-authorized)
        )
      )
      (err err-no-such-commitment)
    )
  )
)

;; Get milestone details
(define-read-only (get-milestone (user principal) (commitment-id uint) (milestone-id uint))
  (let
    (
      (goal-data (map-get? commitments {user: user, commitment-id: commitment-id}))
    )
    (if (is-some goal-data)
      (let
        (
          (unwrapped-goal (unwrap-panic goal-data))
          (privacy (get privacy unwrapped-goal))
          (milestone-data (map-get? stages {user: user, commitment-id: commitment-id, stage-id: milestone-id}))
        )
        (if (and
              (is-some milestone-data)
              (or 
                (is-eq privacy privacy-public)
                (is-eq tx-sender user)
                (is-eq tx-sender (default-to contract-owner (get validator unwrapped-goal)))
              )
            )
          (ok (unwrap-panic milestone-data))
          (if (is-none milestone-data)
            (err err-no-such-stage)
            (err err-not-authorized)
          )
        )
      )
      (err err-no-such-commitment)
    )
  )
)

;; Helper function to compose goal IDs
(define-private (compose-commitment-id (user principal) (id uint))
  {user: user, commitment-id: id}
)

;; Filter function to check if goal is accessible
(define-private (is-accessible-commitment (goal-map {user: principal, commitment-id: uint}))
  (let
    (
      (user (get user goal-map))
      (goal-id (get commitment-id goal-map))
      (goal-data (map-get? commitments {user: user, commitment-id: goal-id}))
    )
    (if (is-some goal-data)
      (let
        (
          (unwrapped-data (unwrap-panic goal-data))
          (privacy (get privacy unwrapped-data))
        )
        (or 
          (is-eq privacy privacy-public)
          (is-eq tx-sender user)
          (is-eq tx-sender (default-to contract-owner (get validator unwrapped-data)))
        )
      )
      false
    )
  )
)

;; =======================================
;; Public Functions
;; =======================================


;; Update goal privacy setting
(define-public (update-goal-privacy (commitment-id uint) (privacy uint))
  (let
    (
      (user tx-sender)
      (goal-data (unwrap! (map-get? commitments {user: user, commitment-id: commitment-id}) (err err-no-such-commitment)))
    )
    ;; Validate
    (asserts! (is-goal-owner user commitment-id) (err err-not-authorized))
    (asserts! (validate-privacy privacy) (err err-invalid-privacy-setting))
    
    ;; Update privacy setting
    (map-set commitments
      {user: user, commitment-id: commitment-id}
      (merge goal-data {privacy: privacy})
    )
    
    (ok true)
  )
)
