#ifndef __HW3_H
#define __HW3_H

#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

typedef struct errorNode{
   int line;
   char * value;
   int type; //variable, date, time error 1,2,3
   struct errorNode *next;
} errorNode;

typedef struct variableNode{ //a double linked list to see the variables and their corresponding values by going to the most recent declaration
   char * name;
   char * value;
   struct variableNode *next;
   struct variableNode *prev;
} variableNode;

typedef struct mainNode{
    bool noError; //a flag to check whether the regular notifications will be printed
    struct variableNode *variableTable;
    struct mailNode *mailStatements;
    struct errorNode *errorStatements;
} mainNode;

typedef struct mailNode{
  char * from;
  struct variableNode *localVariables;
  struct variableNode *localFinal;
  struct scheduleNode *scheduledMails;
  struct sendNode *sendMails;
  struct scheduleNode *scheduleFinal;
  struct sendNode *sendFinal;
  struct mailNode *next;
} mailNode;

typedef struct sendNode{
  struct recipientNode *recipients;
  char * message;
  struct sendNode *next;
} sendNode;

typedef struct scheduleNode{
  char * from;
  char * time;
  char * date;
  struct sendNode *toBeSent;
  struct scheduleNode *next;
} scheduleNode;

typedef struct recipientNode{
  char * value;
  char * address;
  struct recipientNode *next;
} recipientNode;

typedef struct lineStrNode{ //to return both the string and the line it is in from flex
  char * str;
  int line;
} lineStrNode;


variableNode *  createVariable(char * idenName, char * idenVal);
void createGlobalVariable(variableNode * newVar);
void createLocalVariable(variableNode * newVar);
char * retrieveIdent(lineStrNode lineStr, bool flag);
recipientNode * addRecipient(char * value, char * address);
recipientNode * addRecipientList(recipientNode * oneNode, recipientNode * restOfNodes);
void dateChecker(lineStrNode dateInput);
void timeChecker(lineStrNode timeInput);
sendNode * addSendList(sendNode * oneNode, sendNode * restOfNodes);
sendNode * addSendStatement(char * message, recipientNode * recipients);
scheduleNode * addSchedule(char * date, char * time, sendNode * stuffToSend, bool flag);
mailNode * addMailBlock(char * from, mailNode * mail);
void addSchToMail(scheduleNode * sch);
void addSendToMail(sendNode * send);
char *dateFormatter(char *date);
void adjustErrors();

#endif