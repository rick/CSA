#include<stdio.h> 

/*  This file contains a set of c-language functions for generating */
/*  uniform integers.   This is a COMPLETELY PORTABLE generator.    */
/*  It will give IDENTICAL sequences of random numbers for any      */
/*  architecture with at least 30-bit integers, regardless of the   */
/*  integer representation, MAXINT value, or roundoff/truncation    */
/*  method, etc.                                                    */

/*  This Truly Remarkable RNG is described more fully in            */
/*  J. Bentley's column, ``The Software Exploratorium ''            */
/*  to appear in Unix Review in 1991.                               */ 
/*  It is based on one in Knuth, Vol 2, Section 3.2.2 (Algorithm A) */ 

/*----RNG Global Variables-------*/ 

#define PRANDMAX 1000000000
int a; 
int b; 
long arr[55];  

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


/*-----------------------------------------------*/
/* This is a little driver program so you can    */
/* test the code.              */
/* Typing: a.out 0 3 1         */
/* should produce              */
/*     921674862               */
/*     250065336               */
/*     377506581               */
/*  Typing: a.out 1000000 1 2  */ 
/*  should produce             */
/*     57265995                */

main(argc, argv)
int argc;
int *argv;
{
  int i;
  int j;
  int n;
  int m; 
  long seed; 

  m = atoi(argv[1]);    /* Number to discard initially */ 
  n = atoi(argv[2]);    /* Number to print */ 
  seed = atoi(argv[3]); /* Seed */ 

  sprand(seed);

  for (i=0; i < m; i++) j = lprand();
  for (i=0; i < n; i++) printf("%ld\n", lprand());
}/* main*/ 
               



  
