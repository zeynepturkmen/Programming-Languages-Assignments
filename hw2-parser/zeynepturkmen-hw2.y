%{
    #include <stdio.h>
    void yyerror (const char * s){
    return;
    }
%}

%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tSET tTO tFROM tAT tCOMMA tCOLON tLPR tRPR tLBR tRBR tIDENT tSTRING tADDRESS tDATE tTIME

%%

mailProgram :  
            | mail mailProgram
            | set mailProgram;

mail : tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL;

statement : set 
          | send
          | schedule;

statementList: 
            | statement statementList;

recipent : tLPR tADDRESS tRPR
        | tLPR tIDENT tCOMMA tADDRESS tRPR
        | tLPR tSTRING tCOMMA tADDRESS tRPR;

recipents : recipent
          | recipents tCOMMA recipent;

set : tSET tIDENT tLPR tSTRING tRPR;

send : tSEND tLBR tSTRING tRBR tTO tLBR recipents tRBR
    | tSEND tLBR tIDENT tRBR tTO tLBR recipents tRBR;

sendList : send
        | sendList send;

schedule : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendList tENDSCHEDULE;

%%
int main()
{
    if (yyparse()){
        printf("ERROR\n");
        return 1;
    }
    else{
        printf("OK\n");
        return 0;
    }
}