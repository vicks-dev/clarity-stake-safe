;; StakeSafe Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-stake (err u101))
(define-constant err-stake-not-mature (err u102))
(define-constant err-no-stake-found (err u103))
(define-constant minimum-stake u1000)
(define-constant minimum-lock-period u144) ;; ~24 hours in blocks
(define-constant rewards-rate u5) ;; 0.5% per period

;; Data Variables
(define-data-var total-staked uint u0)
(define-data-var total-stakers uint u0)

;; Data Maps
(define-map stakes principal 
  {
    amount: uint,
    start-block: uint,
    lock-period: uint,
    rewards-claimed: uint
  }
)

;; Private Functions
(define-private (calculate-rewards (stake-amount uint) (blocks-staked uint))
  (let (
    (rate (/ (* stake-amount rewards-rate) u1000))
    (periods (/ blocks-staked minimum-lock-period))
  )
  (* rate periods))
)

;; Public Functions
(define-public (stake (amount uint) (lock-blocks uint))
  (let (
    (stake-map (default-to 
      {amount: u0, start-block: u0, lock-period: u0, rewards-claimed: u0} 
      (map-get? stakes tx-sender)))
  )
  (asserts! (>= amount minimum-stake) (err-insufficient-stake))
  (asserts! (>= lock-blocks minimum-lock-period) (err-stake-not-mature))
  
  (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
  
  (if (is-eq (get amount stake-map) u0)
    (var-set total-stakers (+ (var-get total-stakers) u1))
    true
  )
  
  (var-set total-staked (+ (var-get total-staked) amount))
  
  (ok (map-set stakes tx-sender 
    {
      amount: (+ (get amount stake-map) amount),
      start-block: block-height,
      lock-period: lock-blocks,
      rewards-claimed: u0
    }))
  ))
)

(define-public (withdraw (amount uint))
  (let (
    (stake-map (unwrap! (map-get? stakes tx-sender) err-no-stake-found))
    (stake-amount (get amount stake-map))
    (start-block (get start-block stake-map))
    (lock-period (get lock-period stake-map))
  )
  (asserts! (>= stake-amount amount) (err-insufficient-stake))
  (asserts! (>= block-height (+ start-block lock-period)) (err-stake-not-mature))
  
  (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
  
  (var-set total-staked (- (var-get total-staked) amount))
  
  (let ((new-stake-amount (- stake-amount amount)))
    (if (is-eq new-stake-amount u0)
      (begin
        (map-delete stakes tx-sender)
        (var-set total-stakers (- (var-get total-stakers) u1))
      )
      (map-set stakes tx-sender 
        {
          amount: new-stake-amount,
          start-block: start-block,
          lock-period: lock-period,
          rewards-claimed: (get rewards-claimed stake-map)
        })
    )
  )
  (ok true))
)

(define-public (claim-rewards)
  (let (
    (stake-map (unwrap! (map-get? stakes tx-sender) err-no-stake-found))
    (blocks-staked (- block-height (get start-block stake-map)))
    (reward-amount (calculate-rewards (get amount stake-map) blocks-staked))
  )
  (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
  
  (map-set stakes tx-sender 
    (merge stake-map {rewards-claimed: (+ (get rewards-claimed stake-map) reward-amount)}))
  
  (ok reward-amount))
)

;; Read Only Functions
(define-read-only (get-stake (staker principal))
  (map-get? stakes staker)
)

(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)

(define-read-only (get-total-stakers)
  (ok (var-get total-stakers))
)

(define-read-only (get-pending-rewards (staker principal))
  (let (
    (stake-map (unwrap! (map-get? stakes staker) err-no-stake-found))
    (blocks-staked (- block-height (get start-block stake-map)))
  )
  (ok (calculate-rewards (get amount stake-map) blocks-staked)))
)