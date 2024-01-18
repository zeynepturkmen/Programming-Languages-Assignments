(define define-stmt? (lambda (e);;ok so here it should have 3 elements in total the third can be anything will be considered as a single item if its a list or sth
    (and (list? e) (equal? (car e) 'define) (symbol? (cadr e)) (= (length e) 3))))

(define get-value (lambda (var env) 
    (cond
    ((null? env) #f) ;;return false no value found AND our program doesn't have booleans so its fine to return this 
    ((equal? (caar env) var) (cdar env)) ;;if theres a matching symbol return the corresponding value
    (else (get-value var (cdr env)))))) ;;recursively keep searching 

(define get-operator (lambda (op-symbol)
  (cond
    ((eq? op-symbol '+) +)
    ((eq? op-symbol '*) *)
    ((eq? op-symbol '-) -)
    ((eq? op-symbol '/) /)
    (else #f))));;this is a dead condition but anyway

(define is-regular-operator? (lambda (op-symbol)
  (cond
    ((or (eq? op-symbol '+) (eq? op-symbol '*) (eq? op-symbol '-) (eq? op-symbol '/)) #t)
    (else #f))))

(define is-custom-operator? (lambda (operation env) ;;checks whether its value is a lambda expression
  (cond
    ((lambda-stmt? (get-value operation env)) #t)
    (else #f)
  )))

(define extend-env (lambda (var val old-env);;append the new var to the beginning
	(cons (cons var val) old-env)))

(define if-stmt? (lambda (e) ;;ok so here it should have 4 elements in total starts with if the rest of items can be any type of expr
    (and (list? e) (equal? (car e) 'if) (= (length e) 4))))

(define let-stmt? (lambda (e);;ok so here it should have 3 things in: "let", "variables" and the "expr" that uses the variables
    (and (list? e) (equal? (car e) 'let) (list? (cadr e)) (= (length e) 3) (variable-definition-format? (cadr e)) (no-dupe-entry? (map car (cadr e)) '())))) ;;map will just clear and make it a list like (x y z)

(define variable-definition-format?(lambda (e) ;;e is the list of all assignments like x 1 y x stuff like that just checks their format here 2 items first is symbol etc
    (cond 
        ((null? e) #t) ;;its true if its null
        ((not(and (list? (car e)) (= (length (car e)) 2) (symbol? (caar e)))) #f);;an item of it should be a list of 2 elements where the first is a symbol
        (else (variable-definition-format? (cdr e))) ;;recursively check the rest
    )))

(define is-member? (lambda (element someList);;checks whether the element is present in the list
    (cond
       ((null? someList) #f)
       ((equal? (car someList) element) #t)
       (else (is-member? element (cdr someList)))
    )))

(define no-dupe-entry? (lambda (toCheck alreadySeen);;toCheck is the list of all variable names like x y z
   (cond
    ((null? toCheck) #t) ;;no more elements to iterate over its over
    ((is-member? (car toCheck) alreadySeen) #f);;toChecks first element was seen before means dupe entry and not allowed for let-stmt
    (else (no-dupe-entry? (cdr toCheck) (cons (car toCheck) alreadySeen)));;repeat for the rest by adding the element we checked to alreadySeen pile
   )))

(define lambda-stmt? (lambda (e);;ok so here it should have exactly 3 things in: "lamda", "list of variables" and the "expr" that uses the variables
    (and (list? e) (equal? (car e) 'lambda) (list? (cadr e)) (= (length e) 3) (lambda-variable-format? (cadr e)))))

(define lambda-variable-format? (lambda (e);;e is the list of all variables like a b c
    (cond 
        ((null? e) #t) ;;its true if its null
        ((not (symbol? (car e))) #f);;lambda variables should all be identifiers
        (else (lambda-variable-format? (cdr e)))
    )))

(define error-escape (lambda (env) ;;display the error and start back the loop, this gives the "break" effect wherever its called
  (let * (
    (dummy1 (display "cs305: ERROR\n\n")))
    (repl env)
  )))

(define repl (lambda (env) (let* (
	(dummy1 (display "cs305> "))
	(expr (read))
  (result (s7-interpret expr env));;if an error occurs inside this te repl is restarted so below code wont run, erroneous expr wont be assigned to define
	(new-env (if (define-stmt? expr) ;;extend the global environment
            (extend-env (cadr expr) result env) env));;not a define so env remains the same
	(val 
    (cond
        ((define-stmt? expr)(cadr expr)) ;;return the variable symbol defined
        ((lambda-stmt? expr)("[PROCEDURE]")) ;;if its just a lambda with no assignments, return "procedure"
        (else result) ;;whatever the calculated value is
    )
  )
	(dummy2 (display "cs305: "))
	(dummy3 (display val))
	(dummy4 (display "\n\n")))
  (repl new-env))))

(define s7-interpret (lambda (e env)
    (cond
        ((number? e) e) ;;if its a number simply return
        ((is-regular-operator? e) "[PROCEDURE]")
        ((symbol? e) 
          (let ((value (get-value e env)));;if the value is a lambda statement just print PROCEDURE
            (if (lambda-stmt? value)
              "[PROCEDURE]"
              (if value value 
                (error-escape env);;no valid value found break everything
                ;;could have added the escape thing inside get-value but that would mean creating copies fo the original environment for every recursion
                ;;cuz the repl escape requires the original env, so this is better for memory and works just as well since the grammar doesnt have true and false expressions
              )
            )
          )
        )
        ((not (list? e)) (error-escape env)) ;;something other than a list means weird syntax just return an error
        ((if-stmt? e)
          (if (not(equal?(s7-interpret(cadr e) env) 0)) ;;anything but 0 is considered true
            (s7-interpret(caddr e) env)
            (s7-interpret(cadddr e) env)
          )
        )
        ((define-stmt? e) 
          (s7-interpret (caddr e) env) ;;evaluate what is in define
        )
        ((let-stmt? e);;it is a let statement time to play with env.. it does binding and uses its environment on top of the global one
           (let* (
                (symbol-list (map car (cadr e))) ;; assign by using lists at the same time cuz we want the values taken from global not each other, this is x y z
                (actual-values (map s7-interpret (map cadr (cadr e)) (make-list (length (cadr e)) env))) ;; this should be what they are assigned to 4 5 6
                (updated-env (append (map cons symbol-list actual-values) env))) ;;append them all as pairs to the original env
            (s7-interpret (caddr e) updated-env) ;; after getting them create a new env and run the statements
          )
        )
        ((is-regular-operator? (car e));;just an expr with a regular operator s6's code 
            (let (
                (operator (get-operator (car e)))
                (operands (map s7-interpret (cdr e) (make-list (length (cdr e) ) env))))
              (apply operator operands))
        )
        ((is-custom-operator? (car e) env);;custom expression
          ;;first extract the actual procedure from memory
          (let ((procedure (get-value (car e) env)) (operands (map s7-interpret(cdr e) (make-list (length (cdr e)) env))))
            (if procedure 
              (cond
                ((not(equal? (length (cadr procedure)) (length operands))) (error-escape env));;the variables and input counts dont match
                (else ;;update the environment witht he given inputs and run the procedure
                  (let ((updated-env (append (map cons (cadr procedure) operands) env)))
                    (s7-interpret (caddr procedure) updated-env))
              ))
            (error-escape env)) ;;procedure not defined
          )
        )
        ((lambda-stmt? e) e) ;;its just lambda dont evaluate simply return as a list
        ((lambda-stmt? (car e));;it is defined and used right away aka no assignments
           (let ((procedure (car e)) (operands (map s7-interpret(cdr e) (make-list (length (cdr e) ) env))))
            (cond
              ((not(equal? (length (cadr procedure)) (length operands))) (error-escape env)) 
              (else (let ((updated-env (append (map cons (cadr procedure) operands) env)))
                (s7-interpret (caddr procedure) updated-env)))
            )
          )
        )
        (else 
         (error-escape env)
        ))))

(define cs305 (lambda () (repl '()))) ;;could have allowed overriding operators by giving them as an input here before initializing