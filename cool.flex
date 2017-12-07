/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <algorithm>
#include <map>
#include <vector>

#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

std::map<char, char> get_special_chars() {
    std::map<char, char> special_chars;
    special_chars['n'] = '\n';
    special_chars['b'] = '\b';
    special_chars['t'] = '\t';
    special_chars['f'] = '\f';
    return special_chars;
}

void remove_surrounding_quotes(std::string& str) {
    str.resize(str.size() - 1);
    str.erase(0, 1);
}

std::string escape(const std::string& str) {
    std::string escaped;
    std::map<char, char> special_chars = get_special_chars();
    for (size_t i = 0; i < str.size() - 1; i++) {
       if (str[i] == '\\') {
            std::map<char, char>::iterator special_char = special_chars.find(str[i + 1]);
            if (special_char != special_chars.end()) {
                escaped.push_back(special_char->second);
                i++; // Skip special char.
            }
        } else {
            escaped.push_back(str[i]);
        }
    }
    return escaped;
}


std::string extract_string_content(std::string& str) {
    remove_surrounding_quotes(str);
    if (str.size() > 0) {
        str = escape(str);
    }
    return str;
}

%}

/*
 * Define names for regular expressions here.
 */

LOWERCASE       [a-z]
UPPERCASE       [A-Z]
DIGIT           [0-9]

ID_CHAR         {LOWERCASE}|{UPPERCASE}|{DIGIT}|_

STR_CONTENT     (.*(\\\n)?)*

/*
 * Keywords.
 */

CLASS           (?i:class)
ELSE            (?i:else)
FI              (?i:fi)
IF              (?i:if)
IN              (?i:in)
INHERITS        (?i:inherits)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
OF              (?i:of)
DARROW          =>
NEW             (?i:new)
ISVOID          (?i:isvoid)
NOT             (?i:not)
ASSIGN          <-
LE              <=

SYMBOL          \+|\/|-|\*|=|<|\.|~|,|;|:|\(|\)|@|\{|\}

BOOL_TRUE       t(?i:rue)
BOOL_FALSE      f(?i:alse)

STRING          \"{STR_CONTENT}\"
UNTERMINATED_STRING  \"{STR_CONTENT}<<EOF>>

TYPEID          {UPPERCASE}{ID_CHAR}*
OBJECTID        {LOWERCASE}{ID_CHAR}*

INT             {DIGIT}*

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */

{CLASS}         { return CLASS; }
{ELSE}          { return ELSE; }
{FI}            { return FI; }
{IF}            { return IF; }
{IN}            { return IN; }
{INHERITS}      { return INHERITS; }
{LET}           { return LET; }
{LOOP}          { return LOOP; }
{POOL}          { return POOL; }
{THEN}          { return THEN; }
{WHILE}         { return WHILE; }
{CASE}          { return CASE; }
{ESAC}          { return ESAC; }
{OF}            { return OF; }
{DARROW}		{ return DARROW; }
{NEW}           { return NEW; }
{ISVOID}        { return ISVOID; }
{NOT}           { return NOT; }
{ASSIGN}        { return ASSIGN; }
{LE}            { return LE; }

{SYMBOL}        { return yytext[0]; }

{BOOL_TRUE} {
    cool_yylval.boolean = true;
    return BOOL_CONST;
}

{BOOL_FALSE} {
    cool_yylval.boolean = false;
    return BOOL_CONST;
}

{TYPEID} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return TYPEID;
}

{OBJECTID} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return OBJECTID;
}

{INT} {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}

{STRING} {
    std::string str = yytext;

    curr_lineno += std::count(str.begin(), str.end(), '\n');

    char* content = &extract_string_content(str)[0];
    cool_yylval.symbol = stringtable.add_string(content);
    return STR_CONST;
}

\n {
    curr_lineno++;
}

.

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%

