%{

#include "defines.h"

using namespace std;
using namespace boost;

//// IDK ////
extern int yylex();
extern void yyerror(char*);
void Div0Error(void);
void UnknownVarError(string s);
//// IDK ////

// our top level module defined in main.c

extern module_t* module;
%}

%union {

  int     int_type;
  double  double_type;
  string* string_type;

  port_list_t* ports_list;
  port_t* port_val;
  port_type_t port_type_val;
  port_direction_t port_dir_val;

  // variables go here.

  // assume we dont need transitions lol

  vector<string>* string_list;

  // we need always block
}

%start module

%token <int_type>    MODULE ENDMODULE
%token <int_type>    INPUT OUTPUT 
%token <int_type>    BEGIN_BLOCK END_BLOCK


%token <int_type>    RPAREN LPAREN 
%token <int_type>    SEMICOLON 
%token <int_type>    COLON 
%token <int_type>    PLUS 
%token <int_type>    COMMA 
%token <int_type>    ASSIGN 
%token <int_type>    LBRACKET RBRACKET
%token <int_type>    LSQUAREBRACKET RSQUAREBRACKET

%token <string_type> VARIABLE
%token <double_type> NUMBER

%type <ports_list> ports_block;
%type <ports_list> ports;
%type <port_val>  port;
%type <port_type_val> port_type;
%type <port_dir_val>  port_dir;

%type <string_list> names;

%%

// module
module      : MODULE ports_block var_block always_block ENDMODULE 
              { 
              } ;

// ports
ports_block   : LPAREN ports RPAREN SEMICOLON 
                {
/*
                  p->ports = $2;
                  $$ = $2;
*/
                } ; 

ports         : ports port
                {
/*
                  $1->push_back($2);
                  $$ = $1;
*/
                }
              | port 
                { 
/*
                  port_list_t* ports = new port_list_t();
                  ports->push_back($1);
                  $$ = ports;
*/
                } ; 

port          : port_type port_dir NUMBER VARIABLE 
                { 
/*
                  port_t* port = new port_t($1, $2, $3, $4); 
                  $$ = port;
*/
                }
              | port_type NUMBER VARIABLE 
                {
/*
                  port_t* port = new port_t($1, PORT_DIR_NULL, $2, $3); 
                  $$ = port;
*/
                } ;

port_dir      : IN      { /* $$ = PORT_DIR_IN; */ } 
              | OUT     { /* $$ = PORT_DIR_OUT; */ } ;

port_type     : DATA    { /* $$ = PORT_TYPE_DATA; */   }
              | CONTROL { /* $$ = PORT_TYPE_CONTROL; */ } ;



states_block  : ATSIGN LPAREN states RPAREN
                {  
                  $$ = $3;
                } ;

states        : states COMMA state
                {  
                  state_t new_state = *($3);
                  $1->push_back(new_state);
                  $$ = $1;
                }
              | state        
                {  
                  state_list_t* state_list = new state_list_t(); 
                  state_t new_state = *($1);
                  state_list->push_back(new_state);
                  $$ = state_list;
                } ;

state         : VARIABLE LPAREN value RPAREN 
                { 
                  string portname = *($1);
                  value_t val = *($3);
                  state_t* state = new state_t(portname, val);
                  $$ = state;
                } ;

// we shud not support variable states, there is no point.
value         : NUMBER   
                { 
                  int num = $1;
                  $$ = new value_t(VALUE_TYPE_NUMBER, num); 
                }
              | VARIABLE 
                { 
                  string var = *($1);
                  $$ = new value_t(VALUE_TYPE_VARIABLE, var);  
                } ; 

// behavior
behavior_block : BEHAVIOR behavior ENDBEHAVIOR 
                 {  
                   // do nothing
                 } ;

behavior       : sequence 
                 {
                   // do nothing
                 } ;

sequence       : transitions
                 {
                   int i, j;

                   // add ROOT to graph
                   int root = p->behavior->add_root();
                   for(i=0; i<$1->head.size(); i++) {
                     p->behavior->add_edge(root, $1->head[i], $1->edge[i]);
                   }

                   // we are going to make all the end vertices sinks
                   for(i=0; i<$1->tail.size(); i++) {
                     p->behavior->set_sink($1->tail[i]);
                   }

                   
/*
                   // can we not do it this way?
                   for(i=0; i<$1->head.size(); i++) {
                     p->behavior->add_edge(sink, $1->head[i], $1->edge[i]);
                   }
*/
                 
                   // this is how we would connect tail to head.
                   // but this currently gives infinate loop
/*
                   for(i=0; i<$1->tail.size(); i++) {
                     for(j=0; j<$1->head.size(); j++) {
                       p->behavior->add_edge($1->tail[i], $1->head[j], $1->edge[j]);
                     }
                   }
*/


                 } ;

// need to combine transition_block and transition into same type to make this smaller.
transitions      : transitions transition_block
                   {
                     int i, j;
                     for(i=0; i<$1->tail.size(); i++) {
                       for(j=0; j<$2->head.size(); j++) {
                         // big mistake here. edge[i]. shud be the same as head.
                         p->behavior->add_edge($1->tail[i], $2->head[j], $2->edge[j]); 
                       }
                     }
                     $1->set_tail($2->tail);
                     $$ = $1;
                   } 
                 | transitions transition
                   {
                     int i;
                     for(i=0; i<$1->tail.size(); i++) {
                       p->behavior->add_edge($1->tail[i], $2->head, $2->edge);
                     }
                     $1->set_tail($2->tail);
                     $$ = $1;
                   } 
                 | transitions generate
                   {
                     int i, j;
                     for(i=0; i<$1->tail.size(); i++) {
                       for(j=0; j<$2->head.size(); j++) {
                         // big mistake here. edge[i]. shud be the same as head.
                         p->behavior->add_edge($1->tail[i], $2->head[j], $2->edge[j]); 
                       }
                     }
                     $1->set_tail($2->tail);
                     $$ = $1;
                   }
                 | transition_block
                   {
                     $$ = $1;
                   } 
                 | transition
                   {
                     forest_transition_t* t = new forest_transition_t();
                     t->add_head($1->head);
                     t->add_edge($1->edge);
                     t->set_tail($1->tail);
                     $$ = t;
                   }
                 | generate 
                   {
                     $$ = $1;
                   } ;

transition_block : BEGIN_BLOCK transition_list END_BLOCK
                   {
                     $$ = $2;
                   } ;

// this is not gonna work, this could return a connection list
transition_list  : transition_list ORBAR transition_list_item
                   {
                     $1->add_head($3->head);
                     $1->add_edge($3->edge);
                     $1->add_tail($3->tail);
                   } 
                 | ORBAR transition_list_item
                   { 
                     $$ = $2;
                   } ;

transition_list_item : transition_list_item transitions
                       {
                         int i, j;
                         for(i=0; i<$1->tail.size(); i++) {
                           for(j=0; j<$2->head.size(); j++) {
                             p->behavior->add_edge($1->tail[i], $2->head[j], $2->edge[j]);
                           }
                         }
                         $1->set_tail($2->tail);
                         $$ = $1;
                       }
                     | generate
                       {
                         $$ = $1;
                       }
                     | transition
                       {
                         forest_transition_t* t = new forest_transition_t();
                         t->add_head($1->head);
                         t->add_edge($1->edge);
                         t->set_tail($1->tail);
                         $$ = t;
                       } ;

transition       : PLUS edge
                   {
                     int v = p->behavior->add_vertex();

                     tree_transition_t* t = new tree_transition_t();
                     t->add_head(v);
                     t->add_edge( $2 );
                     t->add_tail(v);
                     $$ = t;
                   } ;

generate_transition : PLUS edge
                      {
                        // int v = p->behavior->add_vertex();

                        tree_transition_t* t = new tree_transition_t();
                        // t->add_head(v);
                        t->add_edge( $2 );
                        // t->add_tail(v);
                        $$ = t;
                      } ;

// this is silly and it shud be fixed.
edge             : states_block LBRACKET send_block receive_block RBRACKET
                   {
                     state_list_t conditions = *($1);
                     vector<string> sends = *($3);
                     vector<string> receives = *($4);
                     edge_t* edge = new edge_t( conditions, sends, receives );
                     $$ = edge;
                   }
                 | states_block LBRACKET receive_block send_block RBRACKET
                   {
                     state_list_t conditions = *($1);
                     vector<string> sends = *($4);
                     vector<string> receives = *($3);
                     edge_t* edge = new edge_t( conditions, sends, receives );
                     $$ = edge;
                   }
                 | states_block LBRACKET send_block RBRACKET
                   {
                     state_list_t conditions = *($1);
                     vector<string> sends = *($3);
                     vector<string> receives;
                     edge_t* edge = new edge_t( conditions, sends, receives );
                     $$ = edge;
                   } 
                 | states_block LBRACKET receive_block RBRACKET
                   {
                     state_list_t conditions = *($1);
                     vector<string> sends;
                     vector<string> receives = *($3);
                     edge_t* edge = new edge_t( conditions, sends, receives );
                     $$ = edge;
                   } 
                 | states_block
                   {
                     state_list_t conditions = *($1);
                     vector<string> sends;
                     vector<string> receives;
                     edge_t* edge = new edge_t( conditions, sends, receives );
                     $$ = edge;
                   } ; 

receive_block      : RECEIVE LPAREN names RPAREN
                     {
                       $$ = $3;
                     } ;

send_block       : SEND LPAREN names RPAREN
                   {
                     $$ = $3;
                   } ;

names            : names COMMA VARIABLE
                   {
                     $1->push_back( *($3) );
                     $$ = $1;
                   }

                 | VARIABLE
                   {
                     vector<string>* list = new vector<string>();
                     list->push_back( *($1) );
                     $$ = list;
                   } ;

// just going to do a single transition for now
// also only doing for a fixed number of transactions
// need to use the map for that later.

// dont need to do the divergence
// can infer from the map
// so smart

/*
for the generate
u are gonna generate N transitions again and attach them all to eachother
there is no 

generate condition begin transation end

generate N name begin transitions end

thats it
*/

generate         : GENERATE VARIABLE ASSIGN NUMBER COLON NUMBER BEGIN_BLOCK generate_transition END_BLOCK
                   {
                     forest_transition_t* top;

                     int i, j;
                     int max = (int) $4;
                     int min = (int) $6;

                     for(i=max; i>=min; i--) {

                       // want to copy the edge out of tree_transition_t
                       edge_t* edge_copy = $8->edge->copy();

                       // change me to max
                       if(i==$4) {
                         int v = p->behavior->add_vertex();

                         top = new forest_transition_t();
                         top->add_head(v);
                         top->add_edge(edge_copy);
                         top->add_tail(v);
                       }
                       else {
                         int v = p->behavior->add_vertex();

                         tree_transition_t* next = new tree_transition_t();
                         next->add_head(v);
                         next->add_edge(edge_copy);
                         next->add_tail(v);

                         for(j=0; j<top->tail.size(); j++) {
                           p->behavior->add_edge(top->tail[j], next->head, next->edge);
                         }

                         top->set_tail(next->tail);
                       }

                     }

                     $$ = top;
                   } 
                 | GENERATE VARIABLE ASSIGN VARIABLE COLON NUMBER BEGIN_BLOCK generate_transition END_BLOCK
                   {
                     // this is in danger of turning into really shitty code
                     forest_transition_t* top;

                     int i, j;

                     string portname = *($4);
                     port_t* port = p->ports->find(portname);

                     int max = (1 << port->width) - 1;
                     int min = (int) $6;

                     value_map_t* map_match = NULL;
                     if (p->maps->map_exists(portname)) {
                       map_match = p->maps->get_map(portname);
                       max = map_match->get_max();
                     };

                     for(i=max; i>=min; i--) {

                       // want to copy the edge out of tree_transition_t
                       edge_t* edge_copy = $8->edge->copy();

                       if(i==max) {
                         int v = p->behavior->add_vertex();

                         top = new forest_transition_t();

                         // OFFICIALLY GARBAGE CODE - LOL
                         if( map_match == NULL || (map_match != NULL && map_match->value_exists(i)) ) {
                           uint32_t num;
                           if (map_match != NULL && map_match->value_exists(i)) {
                             num = map_match->get_key(i);
                           }
                           else {
                             num = i;
                           }

                           state_t new_cond( portname , value_t(VALUE_TYPE_NUMBER, num) );
                           edge_copy->conditions.push_back(new_cond);
                         }

                         top->add_head(v);
                         top->add_edge(edge_copy);
                         top->add_tail(v);
                       }
                       else {
                         int v = p->behavior->add_vertex();

                         tree_transition_t* next = new tree_transition_t();
                         next->add_head(v);
                         next->add_edge(edge_copy);
                         next->add_tail(v);

                         // this really is just 1 for now.
                         for(j=0; j<top->tail.size(); j++) {
                           p->behavior->add_edge(top->tail[j], next->head, next->edge);
                         }

                         top->set_tail(next->tail);

                         // OFFICIALLY GARBAGE CODE - LOL
                         // this is in danger of turning into really shitty code
                         // fix me: i should not copy and waste the transition
                         // to connect root to this one.
                         if( map_match == NULL || (map_match != NULL && map_match->value_exists(i)) ) {
                           edge_t* edge_copy1 = $8->edge->copy();

                           uint32_t num;
                           if (map_match != NULL && map_match->value_exists(i)) {
                             num = map_match->get_key(i);
                           }
                           else {
                             num = i;
                           }

                           state_t new_cond( portname , value_t(VALUE_TYPE_NUMBER, num) );
                           edge_copy1->conditions.push_back(new_cond);

                           top->add_head(v);
                           top->add_edge(edge_copy1);
                         }
                       }
                     }

                     $$ = top;
                   };

maps_block       : map
                   {
                     // p->maps = $1;
                     $$ = $1;
                   } ;

/*
maps             : maps map
                   {
                     // check to make sure that we are not adding duplicate names
                     $1->push_back($2);
                     $$ = $1;
                   }
                 | map
                   {
                     map_list_t* new_map_list = new map_list_t();
                     new_map_list->push_back($1);
                     $$ = new_map_list;
                   } ;
*/
map              : MAP VARIABLE BEGIN_BLOCK mappings END_BLOCK
                   {
                     $4->set_name($2);
                     $$ = $4;
                   } ;

mappings         : mappings mapping
                   {
                     $1->put( *($2) );
                     $$ = $1;
                   }
                 | mapping
                   {
                     value_map_t* new_map = new value_map_t();
                     new_map->put( *($1) );
                     $$ = new_map;
                   } ;

mapping          : NUMBER COLON NUMBER
                   {
                     $$ = new pair<uint32_t, uint32_t>($1, $3);
                   } ;

%%





























