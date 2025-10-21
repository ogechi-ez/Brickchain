;; Tokenized Real Estate Smart Contract

;; Data variables
(define-data-var prop-counter uint u0)

;; Maps to store property details and investor balances
(define-map properties 
  {pid: uint} 
  {
    owner: principal,    ;; Owner of the property
    value: uint,         ;; Market value of the property
    tot-shares: uint,    ;; Total number of shares issued
    sp: uint             ;; Price per share
  }
)

(define-map investors
  {pid: uint, addr: principal} 
  {bal: uint})

;; Event types
(define-data-var evt-id uint u0)

;; Print events instead of define-event
(define-private (emit-property-registered (pid uint) (owner principal) (value uint) (tot-shares uint) (sp uint))
  (print {
    event: "property-registered",
    pid: pid,
    owner: owner,
    value: value,
    tot-shares: tot-shares,
    sp: sp
  })
)

(define-private (emit-shares-purchased (pid uint) (purchaser principal) (shares uint) (cost uint))
  (print {
    event: "shares-purchased",
    pid: pid,
    purchaser: purchaser,
    shares: shares,
    cost: cost
  })
)

(define-private (emit-shares-sold (pid uint) (vendor principal) (shares uint) (amt-refunded uint))
  (print {
    event: "shares-sold",
    pid: pid,
    vendor: vendor,
    shares: shares,
    amt-refunded: amt-refunded
  })
)

(define-private (emit-dividends-distributed (pid uint) (income uint) (div-per-share uint))
  (print {
    event: "dividends-distributed",
    pid: pid,
    income: income,
    div-per-share: div-per-share
  })
)

;; Helper functions
(define-private (get-property (pid uint))
  (map-get? properties {pid: pid}))

(define-private (get-investor (pid uint) (addr principal))
  (map-get? investors {pid: pid, addr: addr}))

;; Check if sender is the property owner
(define-private (is-owner (pid uint))
  (match (get-property pid)
    prop (is-eq tx-sender (get owner prop))
    false))

;; Register a new property and tokenize it into shares
(define-public (register-property (value uint) (tot-shares uint) (sp uint))
  ;; Input validation for property attributes to avoid untrusted data usage
  (if (or (is-eq value u0) (is-eq tot-shares u0) (is-eq sp u0))
    (err u400) ;; Invalid input if any attribute is zero
    (let (
          (pid (+ (var-get prop-counter) u1))
      )
      (begin
        ;; Insert property data into properties map
        (map-insert properties
          {pid: pid}
          {
            owner: tx-sender,
            value: value,
            tot-shares: tot-shares,
            sp: sp
          })
        
        ;; Increment property counter
        (var-set prop-counter pid)
        
        ;; Print event using our print-based function
        (emit-property-registered pid tx-sender value tot-shares sp)
        
        ;; Return the property ID
        (ok pid)
      )
    )
  )
)

;; Buy fractional shares of a property
(define-public (buy-shares (pid uint) (shares uint))
  (begin
    (asserts! (> pid u0) (err u400)) ;; Ensure pid is valid
    (asserts! (> shares u0) (err u400))      ;; Ensure shares is non-zero
    
    (let (
          (prop (unwrap! (get-property pid) (err u404))) ;; Error if property not found
          (curr-bal (default-to u0 (get bal (get-investor pid tx-sender))))
          (cost (* shares (get sp prop)))
    )
      (begin
        (asserts! (>= (stx-get-balance tx-sender) cost) (err u100))
        (map-set investors
          {pid: pid, addr: tx-sender}
          {bal: (+ curr-bal shares)})
        
        (try! (stx-transfer? cost tx-sender (get owner prop)))
        (emit-shares-purchased pid tx-sender shares cost)
        (ok shares)
      )
    )
  )
)

;; Sell fractional shares back to the property owner
(define-public (sell-shares (pid uint) (shares uint))
  (begin
    (asserts! (> pid u0) (err u400))
    (asserts! (> shares u0) (err u400))
    
    (let (
          (inv-data (unwrap! (get-investor pid tx-sender) (err u403)))
          (prop (unwrap! (get-property pid) (err u404)))
          (bal (get bal inv-data))
          (amt-refunded (* shares (get sp prop)))
    )
      (begin
        (asserts! (>= bal shares) (err u101))
        (map-set investors
          {pid: pid, addr: tx-sender}
          {bal: (- bal shares)})
        
        (try! (stx-transfer? amt-refunded (get owner prop) tx-sender))
        (emit-shares-sold pid tx-sender shares amt-refunded)
        (ok amt-refunded)
      )
    )
  )
)

;; Distribute rental income to investors based on share ownership
(define-public (distribute-dividend (pid uint) (inv-addr principal) (income uint))
  (begin
    (asserts! (> pid u0) (err u400))
    (asserts! (> income u0) (err u400))
    
    (let (
          (prop (unwrap! (get-property pid) (err u404)))
          (inv-data (unwrap! (get-investor pid inv-addr) (err u403)))
          (tot-shares (get tot-shares prop))
          (div-per-share (/ income tot-shares))
          (bal (get bal inv-data))
    )
      (begin
        (asserts! (is-owner pid) (err u401))
        (let (
              (div-amt (* bal div-per-share))
        )
          (begin
            (try! (stx-transfer? div-amt tx-sender inv-addr))
            (emit-dividends-distributed pid income div-per-share)
            (ok div-amt)
          )
        )
      )
    )
  )
)