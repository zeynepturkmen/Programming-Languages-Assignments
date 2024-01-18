(define twoOperatorCalculator (lambda (expr) 
    (if (= (length expr) 1) (car expr)
    ;;would come here only if there are at least 3 elements so no problem in calling cdddr
      (let * ((start ((if (eq? (cadr expr) '+) + -)(car expr)(caddr expr))
             ))
        (twoOperatorCalculator (cons start (cdddr expr)))
      )
  )
 )
)

(define fourOperatorCalculator (lambda (expr) 
   (cond
     ((null? expr) '()) ;;return null
     ((= (length expr) 1) expr) ;;return the value itself
     (else ;;2 conditions here add/sub vs mult/division
        (let * ((start 
            (cond 
              ((eq? (cadr expr) '+) (cons (car expr) (list(cadr expr)))) ;;treat first two as a seperate thing not to be modified again
              ((eq? (cadr expr) '-) (cons (car expr) (list(cadr expr))))
              (else ;;apply the operation and move it forward
                ((if (eq? (cadr expr) '*) * /)(car expr)(caddr expr));;start becomes the result of this operation
              )
            )
            ;;a problem: one of them requires calling cddr and other needs cdddr hmm.... lets do another if check
        ));;below return a NEW list by calling the same function on the sublist...
        ;;continue if there were at least 5 elements before we begun, else just return the value I obtained, cuz I either removed 2 or 3 of em
        (if (>= (length expr) 5)
            (if (number? start) 
                (fourOperatorCalculator (cons start (cdddr expr)))
                (append start (fourOperatorCalculator (cddr expr))))
        (if (list? start) expr (list start))
        ))
     )
)))


(define calculatorNested (lambda (expr) 
  (cond
    ((null? expr) '())
    (else (let ((firstElement (car expr)))
      (cond
        ((list? firstElement)     
          (let ((subEvaluated (twoOperatorCalculator(fourOperatorCalculator (calculatorNested firstElement)))))
          (calculatorNested (cons subEvaluated (cdr expr))))
        )
        ((number? firstElement)
          (if (= (length expr) 1)
            expr
            (append (list firstElement) (append (list(cadr expr)) (calculatorNested(cddr expr))))
          )
        )
        (else '(SomethingWentWrong))
      )
    ))
  )
))

(define checkOperators (lambda (expr) 
  (cond
    ((null? expr) #f) ;;return false
    ((not (list? expr)) #f) ;;false if its not a list
    ((= (length expr) 2) #f) ;;if the length is 2 its invalid
    ((= (length expr) 1) ;;length is 1, its element either has to be a number or a sublist
      (if (number? (car expr)) 
        #t ;;it is a number so its true
       (checkOperators(car expr));;recursively call itself to see whether it checks out
      )
    )
    ;;it is a list now check the contents of the list
    ;;i gotta group them as 3s and check the order of operands also hmm
    (else (let (
      (firstElement (car expr));;extract 3 elements
      (secondElement (cadr expr))
      (restOfElements (cddr expr)))
      ;;if its an operator check the rest else return false
      (if (or (eq? secondElement '+) (eq? secondElement '-) (eq? secondElement '* ) (eq? secondElement '/)) 
        ;;check whether element 1 or 3 are valid && check
        (
          and (checkOperators(list firstElement)) (checkOperators restOfElements)
        );;check rest
        #f;;return false
      )
  ))
)))

(define calculator (lambda (expr) 
  (if (checkOperators expr) 
    (twoOperatorCalculator(fourOperatorCalculator(calculatorNested expr)))
    #f
  )
))