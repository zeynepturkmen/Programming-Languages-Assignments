%{ 
  #ifdef YYDEBUG
    yydebug = 1;
  #endif

  #include "zeynepturkmen-hw3.h"

  void yyerror (const char *msg) /* Called by yyparse on error */ {return; }
  struct mainNode * head;
  struct mailNode * dummyMail, * latestMail;
  struct variableNode * latestVar;
  struct errorNode * latestError;
  struct errorNode * tempError;
  struct errorNode * tempErrorHead;
  struct recipientNode * latestRecipient;
  struct sendNode * latestSend;
  struct scheduleNode * firstSchedule;
  struct sendNode * firstSend;
%}

%union {
  char * strVal;
  lineStrNode lineStr;
  scheduleNode * schNodePtr;
  sendNode * sndNodePtr;
  variableNode * varNodePtr;
  recipientNode * rcpntNodePtr;
  mailNode * mailPtr;
}

%token tMAIL tENDMAIL tENDSCHEDULE tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT tSCHEDULE tSEND
%token <strVal> tSTRING tADDRESS
%token <lineStr> tIDENT tDATE tTIME
%type <schNodePtr> scheduleStatement
%type <sndNodePtr> sendStatement sendStatements
%type <varNodePtr> setStatement
%type <rcpntNodePtr> recipient recipientList
%type <mailPtr> statementList mailBlock


%start program
%%

program : statements
;

statements : 
            | statements setStatement{createGlobalVariable($2);}
            | statements mailBlock 
;

//at this point i should have firstSch set as the first item in this mails linked list, firstSend as the send of all other send stuff
//dummy mail is the currently iterated mail
mailBlock : tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL {addMailBlock($3, $5); dummyMail=NULL;}
;

//modify mail pointers everything and return it above to the mail block to fill the from information
statementList : {$$=dummyMail;}
                | statementList setStatement{createLocalVariable($2); $$=dummyMail;}
                | statementList sendStatement {addSendToMail($2); $$=dummyMail;}
                | statementList scheduleStatement {addSchToMail($2); $$=dummyMail;}
;

sendStatements : sendStatement {
                                $$ = $1; //initializing the list set the latest as the first item
                                latestSend = $1;
                               }
                | sendStatements sendStatement {$$ = addSendList($2, $1);}
;

sendStatement : tSEND tLBR tSTRING tRBR tTO tLBR recipientList tRBR {$$ = addSendStatement($3, $7); 
                                                                  adjustErrors();}
                | tSEND tLBR tIDENT tRBR tTO tLBR recipientList tRBR {$$ = addSendStatement(retrieveIdent($3, false), $7); 
                                                                      adjustErrors();}
;

recipientList : recipient {$$ = $1; latestRecipient = $1;}
            | recipientList tCOMMA recipient {$$ = addRecipientList($3, $1);}
;

recipient : tLPR tADDRESS tRPR {$$ = addRecipient(NULL, $2);}
            | tLPR tSTRING tCOMMA tADDRESS tRPR {$$ = addRecipient($2, $4);}
            | tLPR tIDENT tCOMMA tADDRESS tRPR {$$ = addRecipient(retrieveIdent($2, true), $4);}
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendStatements tENDSCHEDULE {dateChecker($4); timeChecker($6); 
  firstSend = NULL;
  if(firstSchedule == NULL){
    $$=addSchedule($4.str,$6.str,$9, false);
  }
  else{
    $$=addSchedule($4.str,$6.str,$9,true);
  }
}
;

setStatement : tSET tIDENT tLPR tSTRING tRPR {$$=createVariable($2.str, $4); /*set identifiers value as the string and put it in the var table*/}
;

%%

void addSendToMail(sendNode * send){

  if(dummyMail==NULL){ //nothing was assigned to this dummy mail before
    struct mailNode * oneMail = (struct mailNode*) malloc(sizeof(mailNode)); 
    oneMail->sendFinal = send;
    oneMail->scheduleFinal = NULL;
    oneMail->localVariables = NULL;
    oneMail->localFinal = NULL;
    oneMail->next = NULL;
    oneMail->sendMails = send;
    dummyMail = oneMail;
  }
  else{
    if(dummyMail->sendMails == NULL){
      dummyMail->sendMails = send;
    }
    else{
      dummyMail->sendFinal->next = send;
      dummyMail->sendFinal = send;
    }
  }
}

void adjustErrors(){
  if(tempError!=NULL){

    if (latestError != NULL){
      latestError->next = tempErrorHead;
      latestError=tempError; //pull latest to its tail 
    } 
    else{
      if (head->errorStatements == NULL) //no error was added previously
      {
        head->errorStatements = tempErrorHead;
      }
      latestError = tempError;
    }
    tempError=NULL;  tempErrorHead=NULL;
  }  
}

void addSchToMail(scheduleNode * sch){

  if(dummyMail == NULL){ //nothing was assigned to this dummy mail before
    struct mailNode * oneMail = (struct mailNode*) malloc(sizeof(mailNode)); 
    oneMail->sendMails = NULL;
    oneMail->scheduleFinal = sch;
    oneMail->sendFinal = NULL;
    oneMail->localVariables = NULL;
    oneMail->localFinal = NULL;
    oneMail->next = NULL;
    oneMail->scheduledMails = sch;
    dummyMail = oneMail;
  }
  else{//ohh sth was added yea but no schedule was added!!!!
    if(dummyMail->scheduledMails == NULL){
      dummyMail->scheduledMails = sch;
    }
    else{
      dummyMail->scheduleFinal->next = sch;
      dummyMail->scheduleFinal = sch;
    }
  }
}

mailNode * addMailBlock(char * from, mailNode * mail){
  if(mail!= NULL){
    mail->from = from;  
    mail->next = NULL;
  }

  if(latestMail == NULL){//no mail was added before
    head->mailStatements=mail;
    latestMail=mail;
  }
  else{
    latestMail->next = mail;
    latestMail = mail;
  }
}

bool isFirstSmaller(char * firstDate, char * firstTime, char * secondDate, char * secondTime) {
    int day, month, year;
    sscanf(firstDate, "%2d%*[-/.]%2d%*[-/.]%4d", &day, &month, &year);

    int day2, month2, year2;
    sscanf(secondDate, "%2d%*[-/.]%2d%*[-/.]%4d", &day2, &month2, &year2);

    if (year < year2) {
        return true;
    } else if (year == year2 && month < month2) {
        return true;
    } else if (year == year2 && month == month2 && day < day2) {
        return true;
    } else if (year == year2 && month == month2 && day == day2) {
        int hour, min;
        sscanf(firstTime, "%2d:%2d", &hour, &min);

        int hour2, min2;
        sscanf(secondTime, "%2d:%2d", &hour2, &min2);
 
        if (hour < hour2) {
            return true;
        } else if ((hour == hour2 && min < min2)) {
            return true;
        } else if (hour == hour2 && min == min2) {
            return true;
        }
    }
    return false;
}

//merging 2 ordered lists for the final result
struct scheduleNode * orderLists(struct scheduleNode * list1, struct scheduleNode * list2) {
    struct scheduleNode * mergedHead = NULL;
    struct scheduleNode * mergedTail = NULL;  

    while (list1 != NULL || list2 != NULL) {
        struct scheduleNode * freshNode = NULL;

        if (list1 != NULL && (list2 == NULL || isFirstSmaller(list1->date, list1->time, list2->date, list2->time))) {//if equal return true!!
            freshNode = list1;
            list1 = list1->next;
        } else {
            freshNode = list2;
            list2 = list2->next;
        }
        if (mergedTail == NULL) {
            mergedHead = freshNode;
            mergedTail = freshNode;
        } else {
            mergedTail->next = freshNode;
            mergedTail = freshNode;
        }
    }
    return mergedHead;
}

struct scheduleNode * insertionSort(struct scheduleNode * listHead, char * from) {
    if(listHead != NULL){
      listHead->from = from;
    }
    if (listHead == NULL || listHead->next == NULL) {
        return listHead;
    }
    struct scheduleNode * sorted = NULL;
    struct scheduleNode * temp = listHead;

    while (temp != NULL) {
        struct scheduleNode * next = temp->next;
        temp->from = from;

        if (sorted == NULL || isFirstSmaller(temp->date, temp->time, sorted->date, sorted->time)) {
            temp->next = sorted;
            sorted = temp;
        } else {
            struct scheduleNode * ptr = sorted;
            while (ptr->next != NULL && isFirstSmaller(ptr->next->date, ptr->next->time, temp->date, temp->time)) {
                ptr = ptr->next;
            }
            temp->next = ptr->next;
            ptr->next = temp;
        }
        temp = next;
    }
    return sorted;
}

struct scheduleNode * sortSchedules(){
  //here u gotta order the ordered linked lists AND fix the date and time format :d
  //this is easier than schedule one we go mail by mail so
  struct mailNode * mailPtr = head->mailStatements;
  struct scheduleNode * totalSorted = NULL;

  while(mailPtr!=NULL){
    char * from = mailPtr->from;
    
    struct scheduleNode *schPtr = mailPtr->scheduledMails;
    struct scheduleNode *orderedSchPtr = insertionSort(schPtr, from); //this gives the sorted and for fields added version
    mailPtr->scheduledMails = orderedSchPtr;
  
    mailPtr = mailPtr->next;
  }

  mailPtr = head->mailStatements;

  while (mailPtr != NULL) {
    totalSorted = orderLists(totalSorted, mailPtr->scheduledMails);
    mailPtr = mailPtr->next;
  }
  return totalSorted;
}

void printSchedule(){
  struct scheduleNode * schNodePtr = sortSchedules();

  while(schNodePtr != NULL){

    struct sendNode *sendPtr = schNodePtr->toBeSent;

    while(sendPtr != NULL){
      struct recipientNode * recipPtr = sendPtr->recipients;

      while(recipPtr != NULL){
        char * recipient;
        if(recipPtr->value != NULL){
          recipient = recipPtr->value;
        }
        else{
          recipient = recipPtr->address;
        }
        printf("E-mail scheduled to be sent from %s on %s, %s to %s: \"%s\"\n", schNodePtr->from, dateFormatter(schNodePtr->date), schNodePtr->time, recipient, sendPtr->message);
        recipPtr = recipPtr->next;
      }
      sendPtr = sendPtr->next;
    }

    schNodePtr = schNodePtr->next;
  }
}

void printSend(){
  //this is easier than schedule one we go mail by mail so
  struct mailNode *mailPtr = head->mailStatements;

  while(mailPtr!=NULL){
    char * from = mailPtr->from;
    struct sendNode *sendPtr = mailPtr->sendMails;

    while(sendPtr != NULL){
      struct recipientNode * recipPtr = sendPtr->recipients;
      while(recipPtr != NULL){
        char * recipient;
        if(recipPtr->value != NULL){
          recipient = recipPtr->value;
        }
        else{
          recipient = recipPtr->address;
        }

        printf("E-mail sent from %s to %s: \"%s\"\n", from, recipient, sendPtr->message);
        recipPtr = recipPtr->next;
      }
      sendPtr = sendPtr->next;
    }
    mailPtr = mailPtr->next;
  }
}

void printEverything(){ /*just testing the variable list now */
  if(head->noError){ //print out the notifications (ps: this is the tricky part)
    printSend();
    printSchedule();
  }
  else{ //print the errors
    struct errorNode *errPtr = head->errorStatements;
    
    while (errPtr != NULL) {
      if(errPtr->type == 1){
        printf("ERROR at line %d: %s is undefined\n", errPtr->line, errPtr->value);
      }
      else if(errPtr->type == 2){
        printf("ERROR at line %d: date object is not correct (%s)\n", errPtr->line, errPtr->value);
      }
      else{
        printf("ERROR at line %d: time object is not correct (%s)\n", errPtr->line, errPtr->value);
      }
      errPtr = errPtr->next;
    }
  }
}

//one list for each mail so I need a bool to track whether its a new mail
scheduleNode * addSchedule(char * date, char * time, sendNode * stuffToSend, bool flag){
  struct scheduleNode * oneSch = (struct scheduleNode*) malloc(sizeof(scheduleNode));
  oneSch->time = time;
  oneSch->date = date;
  oneSch->toBeSent = stuffToSend;
  oneSch->next = NULL;
  return oneSch;
}

//these can appear inside some other stuff so I need a boolean to track whether its the first "send"
sendNode * addSendStatement(char * message, recipientNode * recipients){
  struct sendNode * oneSend = (struct sendNode*) malloc(sizeof(sendNode));
  oneSend->message = message;
  oneSend->recipients = recipients;
  oneSend->next = NULL;
  return oneSend;
}

sendNode * addSendList(sendNode * oneNode, sendNode * restOfNodes){
  latestSend->next = oneNode;
  latestSend = oneNode;
  return restOfNodes; //this is kinda dumb but it will keep assigning it to the same thing and grow the listh through a dummy one, note to self make this smarter if u have time
}

void timeChecker(lineStrNode timeInput){
  int hour, min;
  sscanf(timeInput.str, "%2d:%2d", &hour, &min);

 if (hour < 0 || hour > 23 || min < 0 || min > 59) {
    struct errorNode * newErr = (struct errorNode*) malloc(sizeof(errorNode));
    newErr->value = timeInput.str;
    newErr->line = timeInput.line;
    newErr->type = 3;
    newErr->next = NULL;
    
    if(latestError!=NULL){
      latestError->next = newErr;
      latestError = newErr;
    }
    else{
      latestError = newErr;
    }
    
    if (head->errorStatements == NULL) /*no variable was added previously */
    {
      head->noError = false;
      head->errorStatements = newErr;
    }
 }
}

void dateChecker(lineStrNode dateInput){
  int day, month, year;
  bool flag = true;
  sscanf(dateInput.str, "%2d%*[-/.]%2d%*[-/.]%4d", &day, &month, &year);
  int dayCheck;

  if (day <=0 || month < 1 || month > 12){
    flag = false;
  }
  else{
    if (month == 2){
       if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
                 dayCheck = 29;
            } else {
                dayCheck = 28;
            }
    }
    else if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12){
      dayCheck = 31;
    }
    else{
      dayCheck = 30;
    }
  }

  if(day <= dayCheck){
    flag = true;
  }
  else{
    flag = false;
  }
  if (flag == false){
    struct errorNode * newErr = (struct errorNode*) malloc(sizeof(errorNode));
    newErr->value = dateInput.str;
    newErr->line = dateInput.line;
    newErr->type = 2;

    if(latestError!=NULL){
      latestError->next = newErr;
      latestError = newErr;
    }
    else{
      latestError = newErr;
    }

    if (head->errorStatements == NULL) /*no variable was added previously */
    {
      head->noError = false;
      head->errorStatements = newErr;
    }
  }
}

recipientNode * addRecipientList(recipientNode * oneNode, recipientNode * restOfNodes){
  //uniqueness check needed here I forgot
  struct recipientNode * temp = restOfNodes;
  bool flag = true;

  while(temp != NULL){ //iterate the list to check a matching address, if there is dont add anything to the list
    if(strcmp(temp->address, oneNode->address) == 0){
      flag = false;
    }
    temp = temp->next;
  }

  if(flag){
    latestRecipient->next = oneNode;
    latestRecipient = oneNode; //modify it by adding to the end of the list but return the first item always
  }
  return restOfNodes; //this is kinda dumb but it will keep assigning it to the same thing and grow the listh through a dummy one, note to self make this smarter if u have time
}

recipientNode * addRecipient(char * value, char * address){
  struct recipientNode * oneRecipient = (struct recipientNode*) malloc(sizeof(recipientNode));
  oneRecipient->value = value;
  oneRecipient->address = address;
  oneRecipient->next = NULL;
  return oneRecipient;
}

char * retrieveIdent(lineStrNode lineStr, bool flag){ //retrive the value of the identifier and return it
  //first search here bottom up manner
  if(dummyMail != NULL){

    if (dummyMail->localVariables != NULL){

       struct variableNode * localPtr = dummyMail->localFinal;
      while (localPtr != NULL) {
        if (strcmp(localPtr->name, lineStr.str) == 0) {
          return localPtr->value;
        }
        localPtr = localPtr->prev;
      }
    }
  }
  struct variableNode * ptr = latestVar;
  while (ptr != NULL) {
      if (strcmp(ptr->name, lineStr.str) == 0) {
        return ptr->value;
      }
      ptr = ptr->prev;
  }

  if (flag){//temp add them
    //nothing matching found produce an error at this line
    head->noError = false; 
    
    struct errorNode * newErr = (struct errorNode*) malloc(sizeof(errorNode));
    newErr->value = lineStr.str;
    newErr->line = lineStr.line;
    newErr->type = 1;

    if(tempError == NULL){
      tempErrorHead = newErr;
      tempError = newErr;
    }
    else{
      tempError->next = newErr;
      tempError = newErr;
    }
  }
  else { //directly add
    //nothing matching found produce an error at this line
    head->noError = false; 
    
    struct errorNode * newErr = (struct errorNode*) malloc(sizeof(errorNode));
    newErr->value = lineStr.str;
    newErr->line = lineStr.line;
    newErr->type = 1;

    if(latestError == NULL){
      latestError = newErr;
    }
    else{
      latestError->next = newErr;
      latestError = newErr;
    }
   
    if (head->errorStatements == NULL) //no error was added previously
    {
      head->errorStatements = newErr;
    }
  }
  return NULL;
}

void createGlobalVariable(variableNode * newVar){
  if (head->variableTable == NULL) { //this is the first global variable
    head->variableTable = newVar;
    latestVar = newVar;
  } 
  else {
    newVar->prev = latestVar;
    latestVar->next = newVar;
    latestVar = newVar;
  }
}

void createLocalVariable(variableNode * newVar){
   if(dummyMail==NULL){ //nothing was assigned to this dummy mail before
    struct mailNode * oneMail = (struct mailNode*) malloc(sizeof(mailNode)); 
    oneMail->sendFinal = NULL;
    oneMail->scheduleFinal = NULL;
    oneMail->localVariables = newVar;
    oneMail->localFinal = newVar;
    oneMail->next = NULL;
    oneMail->sendMails = NULL;
    dummyMail = oneMail;
  }
  else{
    if(dummyMail->localVariables == NULL){
      dummyMail->localVariables = newVar;
      dummyMail->localFinal = newVar;
    }
    else{
      newVar->prev = dummyMail->localFinal;
      dummyMail->localFinal->next = newVar;
      dummyMail->localFinal = newVar;
    }
  }
}

variableNode * createVariable(char * idenName, char * idenVal){
	struct variableNode * newVar = (struct variableNode *)malloc(sizeof(variableNode));
  newVar->prev = NULL;
  newVar->name =  idenName;
  newVar->value =  idenVal;
  newVar->next = NULL;
  return newVar;
}

char * dateFormatter(char * date) {
   static const char * months[] = {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
   };

  int day, month, year;
  sscanf(date, "%2d%*[-/.]%2d%*[-/.]%4d", &day, &month, &year);
  
  char result[50];

  snprintf(result, sizeof(result), "%s %d, %d", months[month-1], day, year);

  return strdup(result);
}

int main () 
{
   head = (struct mainNode*) malloc(sizeof(mainNode)); /*initialize the head and make the fields null*/
   latestVar = (struct variableNode*) malloc(sizeof(variableNode)); 
   latestError = (struct errorNode*) malloc(sizeof(errorNode)); 
   latestRecipient = (struct recipientNode*) malloc(sizeof(recipientNode)); 
   latestSend = (struct sendNode*) malloc(sizeof(sendNode)); 
   dummyMail = (struct mailNode*) malloc(sizeof(mailNode)); 
   latestMail = (struct mailNode*) malloc(sizeof(mailNode)); 
   tempError = (struct errorNode*) malloc(sizeof(errorNode)); 
   tempErrorHead = (struct errorNode*) malloc(sizeof(errorNode)); 

   tempErrorHead = NULL;
   latestError = NULL;
   tempError = NULL;
   latestSend = NULL;
   dummyMail= NULL;
   latestVar = NULL;
   latestMail = NULL;

   head->noError = true;
   head->variableTable = NULL;
   head->mailStatements = NULL;
   head->errorStatements = NULL;

   if (yyparse())
   {
      printf("ERROR\n");
      return 1;
    } 
    else 
    {
      printEverything();
      return 0;
    } 
}