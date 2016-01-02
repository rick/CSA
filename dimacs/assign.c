#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

/*-----------------------------------------------------------*/
/*  Generates instances for assignment according to DIMACS   */ 
/*  Challenge format.  Each instance is either a complete    */
/*  bipartite graph with random edge costs, or a bipartite   */
/*  graph with specified out-degree (random destination).    */ 

/*  C. McGeoch, DIMACS 6/91  */

/*  You may need to insert your own random number generators. */
/*     double drand48();  returns doubles from (0.0, 1.0]   */
/*     void srand48(seed); initializes RNG with seed        */  
/*     long seed;                                           */

/*  Sample Input Commands:                  */
/*  nodes  1000                             */
/*  sources  491                            */
/*  maxcost  1000                           */
/*  multiple           (a type of arc cost fctn)  */ 
/*  twocost            (a type of arc cost fctn)  */
/*  complete           (maximum out-degree) */
/*  seed   828272727   (optional)           */

/*  All commands are optional; have defaults; can appear in any  */
/*  order.                                                       */ 
/*    nodes   N   : specifies N nodes; default MAXNODES          */
/*    sources S   : specifies S sources; default 1               */ 
/*    maxcost C   : maximum arc cost; default MAXCOST            */
/*    multiple    : arc (i,j) has cost C*i*j; default random costs */
/*    complete    : specifies maximum out-degree from suppliers  *
/*    degree  D   : specifies out-degree D from suppliers        */ 
/*    seed    X   : specifies X a random seed; default use timer */ 
/*---------------------------------------------------------------*/

#define Assert( cond , msg ) if ( ! (cond) ) {printf("msg\n"); exit(1); } ; 
#define MAXNODES 10000000
#define DEFCOST 100000

#define TRUE 1
#define FALSE 0

typedef char string[50];

/*  RNG Declarations  */
double drand48();
void srand48(); 
long seed;

/* Global Parameters */
int nodes, arcs;      
int degree;           /* vertex degree */ 
int max_cost;         /* max arc cost  */  
int sources, sinks;   /* number of nodes each type */ 
int rand_seed;        /*boolean flag*/ 
int minarcs, maxarcs; /*bounds determined by nodes */ 
int deglimit, complete;  /* boolean flags */ 
int random_costs;         /* boolean flag */

/* Stuff for reading input commands */
string cmdtable[10];
int cmdtable_size; 

/* Hash table stuff */
int htable[MAXNODES]; 
int tablesize; 

/*--------------- Initialize tables and data  */ 
void init()
{ 
  int i; 
  
  cmdtable_size = 7;
  strcpy(cmdtable[0], "sentinel.spot");
  strcpy(cmdtable[1], "nodes" );   /* required */ 
  strcpy(cmdtable[2], "seed");
  strcpy(cmdtable[3], "sources"); 
  strcpy(cmdtable[4], "maxcost");
  strcpy(cmdtable[5], "complete");
  strcpy(cmdtable[6], "degree");   
  strcpy(cmdtable[7], "multiple");

  nodes = MAXNODES;
  rand_seed = TRUE;
  max_cost = DEFCOST; 
  sources = 1;
  deglimit = TRUE; 
  degree = 1; 
  complete = FALSE; 
  random_costs = TRUE; 
}   

/* ---------------- Random number utilities */

/* Initialize rng */  
void init_rand(seed) 
int seed; 
{
  srand48(seed);  /* substitute your own initializer if necessary */ 
}

/* Return an integer from [1..max] */  
int rand_int(max) 
int max;
{
  double x; 
  int i; 
  
  x = drand48(); 
  i = (double) x * max + 1.0;
  return(i);
}

double rand_d()  /* returns doubles from [0, 1.0) */ 
{
  return(drand48());
}
   
/*------------------Command input routines  */ 

/* Lookup command in table */
int lookup(const char *cmd)
{
 int i;
 int stop;
 strcpy( cmdtable[0], cmd);  /* insert sentinel */ 
 stop = 1;
 for (i = cmdtable_size; stop != 0; i--) stop = strcmp(cmdtable[i], cmd);
 return ( i + 1 ); 
}/*lookup*/


/* Get and process input commands  */ 
void get_input()
{
char cmd[50], buf[50];
int index;
int i; 

  while (scanf("%s", cmd ) != EOF) {
    if (fgets(buf, sizeof(buf), stdin) != NULL) {
      index = lookup(cmd);
      switch(index) {
  
      case 0:  { printf("%s: Unknown command. Ignored.\n", cmd);
  	       break;
  	     }
      case 1:  {sscanf( buf , "%d", &nodes); 
  	      Assert( 1<=nodes && nodes<=MAXNODES , Nodes out of range. );
                Assert( nodes<= MAXNODES , Recompile with higher MAXNODES. ); 
  	      break;
  	    }
      case 2: { sscanf( buf, "%ld", &seed);
  	       rand_seed  = FALSE;
  	       break;
  	    }
      case 3: { sscanf( buf, "%d", &sources);
  	      Assert( 1<=sources && sources <= nodes, Sources out of range. );
  	      break; 
  	    }
      case 4: { sscanf( buf, "%d", &max_cost);
                Assert( 1 <= max_cost, Maxcost must be positive. ); 
                break;
              }
      case 5: { complete = TRUE; 
                deglimit = FALSE; 
                break;
              }
      case 6: { sscanf( buf, "%d", &degree);
                Assert( 1 <= degree , Degree must be positive.);
                Assert( degree <= nodes - sources , Degree out of range.); 
                Assert( complete == FALSE , Either complete or degree-not both.) 
                deglimit = TRUE;
                break;
              }              
       case 7: { random_costs = FALSE;
                  break;
              }
      }/*switch*/
    } /* fgets != NULL */
  }/*while*/

sinks = nodes - sources;
if (complete) degree = sinks;
arcs =  sources * degree; 

}/*get_input*/

/*---------------------------Report parameters  */

void report_params()
{
  printf("c Assignment flow problem\n"); 
  printf("c Max arc cost %d\n", max_cost);
  printf("c nodes %d\n", nodes);
  printf("c sources %d \n", sources);
  printf("c out-degree %d \n", degree); 
  if (rand_seed == TRUE) printf("c random seed\n");
  else printf("c seed %ld\n", seed);
}

/*----------------Hash Table Routines ----------------*/
/*Initialize to negative entries                      */ 

void hashinit(entries)
int entries;
{
   int i; 
   tablesize = 2*entries;
   for (i=0; i< tablesize; i++) htable[i] = -1;
 }

int hashfind(item) 
int item;
{
   int hkey;
   
   hkey = item % tablesize;  /* not a great hash function,  */ 
                            /* but items are random.       */ 

   while (htable[hkey] >= 0 ) { /* search non-empty entries */
      if (htable[hkey] == item) 
          return(1);  /* found it */
      else {
         hkey--;
         if (hkey < 0) hkey = tablesize -1; 
       }
    }/*while*/  
   return(0);  /* didnt find it */ 

}/* hashfind */ 

void hashinsert(item)
int item;
{
   int hkey;

   hkey = item % tablesize;  /* not a great hash function,  */ 
                            /* but items are random.       */ 

   while (htable[hkey] >= 0 ) { /* search for empty entry */
         hkey--;                /* note assumes non-ful table   */ 
         if (hkey < 0) hkey = tablesize -1; 
    }/*while*/  

   htable[hkey] = item; 

}/* hashinsert */ 

/*----------------Generate Arcs 1---------------------*/
/* Generate d distinct arcs to sinks, for d < sinks/2 */ 
/* using a hash table.                                */

void generate_arcs1(d, src) 
int d;
int src;
{
   int arc_count;
   int dst;
   int cost; 
      
   hashinit(d); /* initialize hash table to empty */ 

   arc_count = 0;
   while (arc_count < d) {
      dst = rand_int(sinks);

      if (hashfind(dst) == 0 ) { /* not found */
          hashinsert(dst);
          arc_count++;
          
          if (random_costs) cost = rand_int(max_cost); 
          else cost = src * (dst+sources) * max_cost; 

          printf("a  %d  %d  %d  \n", src, dst+sources, cost); 
	} /* if not found */ 
      
    }/*while*/ 
 }/* generate_arc1 */ 

/*------------------Generate Arcs 2------------------------*/
/*Generate arcs w/o replacement when degree >= 2*sinks.    */
/* See  Knuth V2, 3.4.2, Algorithm S                       */

generate_arcs2(howmany, src) 
int howmany; 
int src; 

{
         double have; 
         double seen; 
         double need;  
         double total; 
         double x; 
         int cost; 
         int this; 

         need = (double) howmany; 
         total = (double) sinks; 
         have = 0.0; 
         seen = 0.0;
         this = 1;  
       
         while (have < need) { 
            x = rand_d();
            
           /* choose this with probability=                 */
           /* (number left to chose) / (number left in set) */
             
           if ((total - seen) * x < (need - have) ) {

               if (random_costs) cost = rand_int(max_cost); 
               else cost = src* (sources+this) * max_cost;

              printf("a   %d  %d  %d\n", src, sources+this, cost); 
             
              have += 1.0;
	    }/* if selected */

            seen += 1.0;
            this++;

	  }/* while */ 

}/* generate_arcs2 */

/*--------------------------- Generate and print out network  */ 
void generate_net()
{
 int n, x, j, i;
 int cost; 
 int src, dst; 

  if (rand_seed == TRUE) init_rand((int) time(0));
  else init_rand(seed); 

  /* Print first line and report parameters  */
  printf("p asn  \t %d \t %d \n", nodes, arcs);
  report_params();

  /* Generate  source nodes */
  for (i=1; i <= sources ; i++) {
    printf("n \t %d\n", i);
  }

  /* Generate arcs for each source node */
  if (complete){
     for (i = 1; i<= sources; i++) {
         for (j = sources+1; j<= nodes; j++) {
            if (random_costs) cost = rand_int(max_cost);  
            else cost = i * j * max_cost;

            printf("a  \t  %d  %d  %d \n", i, j, cost );
         }
     } 
   } /* if complete */ 


   /* if limited-degree generat random  destinations */ 
  if (deglimit) {  
       if (degree <= sinks/2) {  /* use one method for sparse networks */ 
           for (i = 1; i<=sources; i++) generate_arcs1(degree, i);
	 }
        else { /* another method for dense networks */
           for (i = 1; i<= sources; i++) generate_arcs2(degree, i); 
	 }
   } /* if deglimit */ 

}/*generate_net*/

/*--------------------main--------------------- */ 
main()
{

    init(); 

    get_input();

    generate_net(); 

  } 
