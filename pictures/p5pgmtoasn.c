/*
Program to convert 'P5' greymap file into an assignment problem.
*/

#include	<stdio.h>
#include	<malloc.h>

unsigned	long	len, wid;
unsigned	long	num_one_side;
extern	void	exit();

#define	FILE_FORMAT	0
#define	FILE_LENGTH	1
#define	TOO_BIG		2

char	*errors[] = {
		    "File format error.",
		    "File length incorrect.",
		    "Image too big; insufficient memory."
		    };

void	errmsg(err)

unsigned	err;

{
(void) puts(errors[err]);
exit(-1);
}

#define	abs(x)	((x) > 0 ? (x) : -(x))

/*
Upper-left corner is lhs node, id = 1.
*/

unsigned	long	node_id(r, c)

unsigned	long	r, c;

{
unsigned	long	pos, offset;

pos = wid * r + c;
offset = (r + c & 0x1 ? num_one_side + 1 : 1);
return(offset + pos / 2);
}

void	arc_out(r0, c0, r1, c1, val)

unsigned	long	r0, c0, r1, c1;
long	val;

{
(void) printf("a %lu %lu %ld\n", node_id(r0, c0), node_id(r1, c1), val);
}

main()

{
char	line[70], file_type[2], *result;
long	pv;
int	ch;
unsigned	long	r, c;
unsigned	char	*greys;
unsigned	long	i;
unsigned	max;
unsigned	long	numgreys;

if (fgets(line, sizeof(line), stdin) != NULL) {
  if ((sscanf(line, "%2s", file_type) == 0) ||
      (file_type[0] != 'P') ||
      (file_type[1] != '5'))
    errmsg(FILE_FORMAT);

  do
    result = fgets(line, sizeof(line), stdin);
  while ((result != NULL) && (line[0] == '#'));

  if (sscanf(line, "%lu%lu", &wid, &len) != 2)
    errmsg(FILE_FORMAT);

  do
    result = fgets(line, sizeof(line), stdin);
  while ((result != NULL) && (line[0] == '#'));

  if (sscanf(line, "%u", &max) != 1)
    errmsg(FILE_FORMAT);
}

/*
Now read greyscale information.
*/
numgreys = len * wid;
if (numgreys & 0x01)
  {
  (void) fprintf(stderr, "Warning: Deleting one row for feasibility.\n");
  numgreys -= wid;
  len--;
  }
if ((greys = (unsigned char *) malloc((unsigned) numgreys)) != NULL)
  {
  for (i = 0; i < numgreys; i++)
    if ((ch = getchar()) != EOF)
      greys[i] = ch;
    else
      {
      (void) fprintf(stderr,
		     "Expected %lu rows, %lu cols, %lu greys; found %lu greys\n",
		     len, wid, numgreys, i);
      errmsg(FILE_LENGTH);
      }
  }
else
  errmsg(TOO_BIG);
/*
Write asn file preamble.
*/
num_one_side = numgreys >> 1;
(void) printf("p asn %lu %lu\n", numgreys, 2 * numgreys - len - wid);
(void) printf("c From %lu x %lu picture\n", len, wid);
for (i = 1; i <= num_one_side; i++)
  (void) printf("n %lu\n", i);
/*
Now produce arcs in asn file.
*/
for (r = 0; r < len; r++)
  for (c = (r & 0x01); c < wid; c += 2)
    {
    if (c != 0)
      {
      pv = greys[r * wid + c] - greys[r * wid + c - 1]; pv = abs(pv);
      arc_out(r, c, r, c - 1, pv);
      }
    if (c != wid - 1)
      {
      pv = greys[r * wid + c] - greys[r * wid + c + 1]; pv = abs(pv);
      arc_out(r, c, r, c + 1, pv);
      }
    if (r != 0)
      {
      pv = greys[r * wid + c] - greys[(r - 1) * wid + c]; pv = abs(pv);
      arc_out(r, c, r - 1, c, pv);
      }
    if (r != len - 1)
      {
      pv = greys[r * wid + c] - greys[(r + 1) * wid + c]; pv = abs(pv);
      arc_out(r, c, r + 1, c, pv);
      }
    }
return(0);
}
