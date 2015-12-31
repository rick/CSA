#include<stdio.h>
#include<math.h>

/*-----------------------------------------------------------*/
/*  Generates instances for geometric matching in   DIMACS    */ 
/*  Challenge format.  Each instance has NODES points uniform */
/*  in d-space (Specified by DIMENSTION) where coordinates are   */
/*  integers in the range 1..MAXLOC.  */

/*  C. McGeoch, DIMACS 6/91  */

/*  Example Input Commands:                 */
/*  nodes  1000                             */
/*  dimension 3                             */
/*  maxloc   1000                           */
/*  seed   828272727   (optional)           */

/*  All command  have defaults; can appear in any  */
/*  order.                                         */ 
/*   nodes   N   : specifies N nodes; default 100  */
/*   dimension D : points in D-space: default 2    */
/*   maxloc  D   : specifies location upper bound; default 100 */ 
/*    degree  D   : specifies out-degree D from supliers         */ 
/*    seed    X   : specifies X a random seed; default use timer */ 
/*---------------------------------------------------------------*/

#define Assert( cond , msg ) if ( ! (cond) ) {printf("msg\n"); exit(); } ; 
#define MAXNODES 1000000
#define TRUE 1
#define FALSE 0
#define PRANDMAX 1000000000

typedef char string[50];

/*----RNG Global Variables-------*/ 
long seed;
int a; 
int b; 
long arr[55];  

/* Global Parameters */
int nodes; 
int dimension;
int maxloc; 
int rand_seed;        /*boolean flag*/ 

/* Stuff for reading input commands */
string cmdtable[10];
int cmdtable_size; 

/*  The uniform RNG below is highly portable.                       */ 
/*  It will give IDENTICAL sequences of random numbers for any      */
/*  architecture with at least 30-bit integers, regardless of the   */
/*  integer representation, MAXINT value, or roundoff/truncation    */
/*  method, etc.                                                    */
/*  Less is known about its randomness properties, although it is   */
/*  recommend by Knuth.  See  J. Bentley's column, ``The Software   */
/*  Exploratorium,''  or Knuth, Vol 2, Section 3.2.2 (Algorithm A) */ 

/*----RNG Initializer------------*/
/* Call once before using lprand */ 

void sprand (seed)
long seed; 
{
  int i, ii;
  long last, next;
  arr[0] = last = seed; 
  next = 1;
  for (i=1; i < 55; i++) {
    ii = ( 21 * i ) % 55;
    arr[ii] = next;
    next = last - next; 
    if (next < 0)
      next += PRANDMAX;
    last = arr[ii];
  }

  a = 0;
  b = 24; 
  for (i = 0; i < 165; i++) 
    last = lprand();
} /* sprand */

/*---------RNG---------------------*/
/* Returns long integers from the  */
/* range 0...PRANDMAX-1            */ 

long lprand()
{    long t;
     if (a-- == 0) a = 54;
     if (b-- == 0) b = 54;

     t = arr[a] - arr[b];

     if (t < 0) t+= PRANDMAX;
     
     arr[a] = t;

     return t;

   }/*lprand*/

/*--------------- Initialize tables and data  */ 
void init()
{ 
  int i; 
  
  cmdtable_size = 4; 
  strcpy(cmdtable[0], "sentinel.spot");
  strcpy(cmdtable[1], "nodes" );   /* required */ 
  strcpy(cmdtable[2], "seed");
  strcpy(cmdtable[3], "dimension"); 
  strcpy(cmdtable[4], "maxloc");

  nodes = MAXNODES;
  rand_seed = TRUE;
  dimension = 2; 
  maxloc = PRANDMAX; 
}   

/* ---------------- Random number utilities */

/* Initialize rng */  
void init_rand(seed) 
long int seed; 
{
  sprand(seed);   
}

/* Return an integer from [1..max] */  
int rand_int(max) 
int max;
{
  double x; 
  int i; 
  
  x = (double) lprand(); 
  i = (int) ((x /PRANDMAX) * max  + 1.0);
  return(i);
}
   
/*------------------Command input routines  */ 

/* Lookup command in table */
int lookup(cmd)
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
    fgets(buf, sizeof(buf), stdin);
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
    case 2: { sscanf( buf, "%d", &seed);
	       rand_seed  = FALSE;
	       break;
	    }
    case 3: { sscanf( buf, "%d", &dimension);
	      break; 
	    }
    case 4: { sscanf( buf, "%d", &maxloc);
              Assert( 1 <= maxloc, Maxloc  must be positive. ); 
              Assert( maxloc <= PRANDMAX,  Too many bits--recompile.);
              break;
            }

    }/*switch*/
  }/*while*/


}/*get_input*/

/*---------------------------Report parameters  */

void report_params()
{
  printf("c Geometric Matching Problem\n"); 
  printf("c nodes %d\n", nodes);
  printf("c dimension %d \n", dimension);
  printf("c max index value  %d \n", maxloc); 
  if (rand_seed == TRUE) printf("c random seed\n");
  else printf("c seed %d\n", seed);
}


/*--------------------------- Generate and print out network  */ 
void generate_graph()
{
 int d, i;

  if (rand_seed == TRUE) init_rand((int) time(0));
  else init_rand(seed); 

  /* Print first line and report parameters  */
  printf("p geom  \t %d \t %d \n", nodes, dimension);
  report_params();

  /* Generate  source nodes */
  for (i=1; i <= nodes ; i++) {
       printf("v "); 
       for (d = 0 ; d < dimension; d++) {
          printf("\t %d", rand_int(maxloc));}
       printf("\n"); 
  }/*for*/
}/*generate_net*/

/*--------------------main--------------------- */ 
main()
{

    init(); 

    get_input();

    generate_graph(); 

  } 
