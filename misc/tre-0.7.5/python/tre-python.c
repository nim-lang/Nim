/*
  tre-python.c - TRE Python language bindings

  Copyright (c) 2004-2006 Nikolai SAOUKH <nms+python@otdel-1.org>

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

*/


#include "Python.h"
#include "structmember.h"

#include <tre/regex.h>

#define	TRE_MODULE	"tre"

typedef struct {
  PyObject_HEAD
  regex_t rgx;
  int flags;
} TrePatternObject;

typedef struct {
  PyObject_HEAD
  regaparams_t ap;
} TreFuzzynessObject;

typedef struct {
  PyObject_HEAD
  regamatch_t am;
  PyObject *targ;	  /* string we matched against */
  TreFuzzynessObject *fz; /* fuzzyness used during match */
} TreMatchObject;


static PyObject *ErrorObject;

static void
_set_tre_err(int rc, regex_t *rgx)
{
  PyObject *errval;
  char emsg[256];
  size_t elen;

  elen = regerror(rc, rgx, emsg, sizeof(emsg));
  if (emsg[elen] == '\0')
    elen--;
  errval = Py_BuildValue("s#", emsg, elen);
  PyErr_SetObject(ErrorObject, errval);
  Py_XDECREF(errval);
}

static PyObject *
TreFuzzyness_new(PyTypeObject *type, PyObject *args, PyObject *kwds)
{
  static char *kwlist[] = {
    "delcost", "inscost", "maxcost", "subcost",
    "maxdel", "maxerr", "maxins", "maxsub",
    NULL
  };

  TreFuzzynessObject *self;

  self = (TreFuzzynessObject*)type->tp_alloc(type, 0);
  if (self == NULL)
    return NULL;
  regaparams_default(&self->ap);
  if (!PyArg_ParseTupleAndKeywords(args, kwds, "|iiiiiiii", kwlist,
				   &self->ap.cost_del, &self->ap.cost_ins,
				   &self->ap.max_cost, &self->ap.cost_subst,
				   &self->ap.max_del, &self->ap.max_err,
				   &self->ap.max_ins, &self->ap.max_subst))
    {
      Py_DECREF(self);
      return NULL;
    }
  return (PyObject*)self;
}

static PyObject *
TreFuzzyness_repr(PyObject *obj)
{
  TreFuzzynessObject *self = (TreFuzzynessObject*)obj;
  PyObject *o;

  o = PyString_FromFormat("%s(delcost=%d,inscost=%d,maxcost=%d,subcost=%d,"
			  "maxdel=%d,maxerr=%d,maxins=%d,maxsub=%d)",
			  self->ob_type->tp_name, self->ap.cost_del,
			  self->ap.cost_ins, self->ap.max_cost,
			  self->ap.cost_subst, self->ap.max_del,
			  self->ap.max_err, self->ap.max_ins,
			  self->ap.max_subst);
  return o;
}

static PyMemberDef TreFuzzyness_members[] = {
  { "delcost", T_INT, offsetof(TreFuzzynessObject, ap.cost_del), 0,
    "The cost of a deleted character" },
  { "inscost", T_INT, offsetof(TreFuzzynessObject, ap.cost_ins), 0,
    "The cost of an inserted character" },
  { "maxcost", T_INT, offsetof(TreFuzzynessObject, ap.max_cost), 0,
    "The maximum allowed cost of a match. If this is set to zero, an exact "
    "match is searched for" },
  { "subcost", T_INT, offsetof(TreFuzzynessObject, ap.cost_subst), 0,
    "The cost of a substituted character" },
  { "maxdel", T_INT, offsetof(TreFuzzynessObject, ap.max_del), 0,
    "Maximum allowed number of deleted characters" },
  { "maxerr", T_INT, offsetof(TreFuzzynessObject, ap.max_err), 0,
    "Maximum allowed number of errors (inserts + deletes + substitutes)" },
  { "maxins", T_INT, offsetof(TreFuzzynessObject, ap.max_ins), 0,
    "Maximum allowed number of inserted characters" },
  { "maxsub", T_INT, offsetof(TreFuzzynessObject, ap.max_subst), 0,
    "Maximum allowed number of substituted characters" },
  { NULL }
};

static PyTypeObject TreFuzzynessType = {
  PyObject_HEAD_INIT(NULL)
  0,			        /* ob_size */
  TRE_MODULE ".Fuzzyness",	/* tp_name */
  sizeof(TreFuzzynessObject),	/* tp_basicsize */
  0,			        /* tp_itemsize */
  /* methods */
  0,				/* tp_dealloc */
  0,				/* tp_print */
  0,				/* tp_getattr */
  0,				/* tp_setattr */
  0,				/* tp_compare */
  TreFuzzyness_repr,		/* tp_repr */
  0,				/* tp_as_number */
  0,				/* tp_as_sequence */
  0,				/* tp_as_mapping */
  0,				/* tp_hash */
  0,				/* tp_call */
  0,				/* tp_str */
  0,				/* tp_getattro */
  0,				/* tp_setattro */
  0,				/* tp_as_buffer */
  Py_TPFLAGS_DEFAULT,		/* tp_flags */
  /* tp_doc */
  TRE_MODULE ".fuzzyness object holds approximation parameters for match",
  0,				/* tp_traverse */
  0,				/* tp_clear */
  0,				/* tp_richcompare */
  0,				/* tp_weaklistoffset */
  0,				/* tp_iter */
  0,				/* tp_iternext */
  0,				/* tp_methods */
  TreFuzzyness_members,		/* tp_members */
  0,				/* tp_getset */
  0,				/* tp_base */
  0,				/* tp_dict */
  0,				/* tp_descr_get */
  0,				/* tp_descr_set */
  0,				/* tp_dictoffset */
  0,				/* tp_init */
  0,				/* tp_alloc */
  TreFuzzyness_new		/* tp_new */
};

static PyObject *
PyTreMatch_groups(TreMatchObject *self, PyObject *dummy)
{
  PyObject *result;
  size_t i;

  if (self->am.nmatch < 1)
    {
      Py_INCREF(Py_None);
      return Py_None;
    }
  result = PyTuple_New(self->am.nmatch);
  for (i = 0; i < self->am.nmatch; i++)
    {
      PyObject *range;
      regmatch_t *rm = &self->am.pmatch[i];

      if (rm->rm_so == (-1) && rm->rm_eo == (-1))
	{
	  Py_INCREF(Py_None);
	  range = Py_None;
	}
      else
	{
	  range = Py_BuildValue("(ii)", rm->rm_so, rm->rm_eo);
	}
      PyTuple_SetItem(result, i, range);
    }
  return (PyObject*)result;
}

static PyObject *
PyTreMatch_groupi(PyObject *obj, int gn)
{
  TreMatchObject *self = (TreMatchObject*)obj;
  PyObject *result;
  regmatch_t *rm;

  if (gn < 0 || (size_t)gn > self->am.nmatch - 1)
    {
      PyErr_SetString(PyExc_ValueError, "out of bounds");
      return NULL;
    }
  rm = &self->am.pmatch[gn];
  if (rm->rm_so == (-1) && rm->rm_eo == (-1))
    {
      Py_INCREF(Py_None);
      return Py_None;
    }
  result = PySequence_GetSlice(self->targ, rm->rm_so, rm->rm_eo);
  return result;
}

static PyObject *
PyTreMatch_group(TreMatchObject *self, PyObject *grpno)
{
  PyObject *result;
  long gn;

  gn = PyInt_AsLong(grpno);

  if (PyErr_Occurred())
    return NULL;

  result = PyTreMatch_groupi((PyObject*)self, gn);
  return result;
}

static PyMethodDef TreMatch_methods[] = {
  {"group", (PyCFunction)PyTreMatch_group, METH_O,
   "return submatched string or None if a parenthesized subexpression did "
   "not participate in a match"},
  {"groups", (PyCFunction)PyTreMatch_groups, METH_NOARGS,
   "return the tuple of slice tuples for all parenthesized subexpressions "
   "(None for not participated)"},
  {NULL, NULL}
};

static PyMemberDef TreMatch_members[] = {
  { "cost", T_INT, offsetof(TreMatchObject, am.cost), READONLY,
    "Cost of the match" },
  { "numdel", T_INT, offsetof(TreMatchObject, am.num_del), READONLY,
    "Number of deletes in the match" },
  { "numins", T_INT, offsetof(TreMatchObject, am.num_ins), READONLY,
    "Number of inserts in the match" },
  { "numsub", T_INT, offsetof(TreMatchObject, am.num_subst), READONLY,
    "Number of substitutes in the match" },
  { "fuzzyness", T_OBJECT, offsetof(TreMatchObject, fz), READONLY,
    "Fuzzyness used during match" },
  { NULL }
};

static void
PyTreMatch_dealloc(TreMatchObject *self)
{
  Py_XDECREF(self->targ);
  Py_XDECREF(self->fz);
  if (self->am.pmatch != NULL)
    PyMem_Del(self->am.pmatch);
  PyObject_Del(self);
}

static PySequenceMethods TreMatch_as_sequence_methods = {
  0, /* sq_length */
  0, /* sq_concat */
  0, /* sq_repeat */
  PyTreMatch_groupi, /* sq_item */
  0, /* sq_slice */
  0, /* sq_ass_item */
  0, /* sq_ass_slice */
  0, /* sq_contains */
  0, /* sq_inplace_concat */
  0 /* sq_inplace_repeat */
};

static PyTypeObject TreMatchType = {
  PyObject_HEAD_INIT(NULL)
  0,			        /* ob_size */
  TRE_MODULE ".Match",		/* tp_name */
  sizeof(TreMatchObject),	/* tp_basicsize */
  0,			        /* tp_itemsize */
  /* methods */
  (destructor)PyTreMatch_dealloc, /* tp_dealloc */
  0,			        /* tp_print */
  0,				/* tp_getattr */
  0,				/* tp_setattr */
  0,				/* tp_compare */
  0,				/* tp_repr */
  0,				/* tp_as_number */
  &TreMatch_as_sequence_methods,	/* tp_as_sequence */
  0,				/* tp_as_mapping */
  0,				/* tp_hash */
  0,				/* tp_call */
  0,				/* tp_str */
  0,				/* tp_getattro */
  0,				/* tp_setattro */
  0,				/* tp_as_buffer */
  Py_TPFLAGS_DEFAULT,		/* tp_flags */
  TRE_MODULE ".match object holds result of successful match",	/* tp_doc */
  0,				/* tp_traverse */
  0,				/* tp_clear */
  0,				/* tp_richcompare */
  0,				/* tp_weaklistoffset */
  0,				/* tp_iter */
  0,				/* tp_iternext */
  TreMatch_methods,		/* tp_methods */
  TreMatch_members		/* tp_members */
};

static TreMatchObject *
newTreMatchObject(void)
{
  TreMatchObject *self;

  self = PyObject_New(TreMatchObject, &TreMatchType);
  if (self == NULL)
    return NULL;
  memset(&self->am, '\0', sizeof(self->am));
  self->targ = NULL;
  self->fz = NULL;
  return self;
}

static PyObject *
PyTrePattern_match(TrePatternObject *self, PyObject *args)
{
  PyObject *pstring;
  int eflags = 0;
  TreMatchObject *mo;
  TreFuzzynessObject *fz;
  size_t nsub;
  int rc;
  regmatch_t *pm;
  char *targ;
  size_t tlen;

  if (!PyArg_ParseTuple(args, "SO!|i:match", &pstring, &TreFuzzynessType,
			&fz, &eflags))
    return NULL;

  mo = newTreMatchObject();
  if (mo == NULL)
    return NULL;

  nsub = self->rgx.re_nsub + 1;
  pm = PyMem_New(regmatch_t, nsub);
  if (pm != NULL)
    {
      mo->am.nmatch = nsub;
      mo->am.pmatch = pm;
    }
  else
    {
      /* XXX */
      Py_DECREF(mo);
      return NULL;
    }

  targ = PyString_AsString(pstring);
  tlen = PyString_Size(pstring);

  rc = reganexec(&self->rgx, targ, tlen, &mo->am, fz->ap, eflags);

  if (PyErr_Occurred())
    {
      Py_DECREF(mo);
      return NULL;
    }

  if (rc == REG_OK)
    {
      Py_INCREF(pstring);
      mo->targ = pstring;
      Py_INCREF(fz);
      mo->fz = fz;
      return (PyObject*)mo;
    }

  if (rc == REG_NOMATCH)
    {
      Py_DECREF(mo);
      Py_INCREF(Py_None);
      return Py_None;
    }
  _set_tre_err(rc, &self->rgx);
  Py_DECREF(mo);
  return NULL;
}

static PyMethodDef TrePattern_methods[] = {
  { "match", (PyCFunction)PyTrePattern_match, METH_VARARGS,
    "try to match against given string, returning " TRE_MODULE ".match object "
    "or None on failure" },
  {NULL, NULL}
};

static PyMemberDef TrePattern_members[] = {
  { "nsub", T_INT, offsetof(TrePatternObject, rgx.re_nsub), READONLY,
    "Number of parenthesized subexpressions in regex" },
  { NULL }
};

static void
PyTrePattern_dealloc(TrePatternObject *self)
{
  regfree(&self->rgx);
  PyObject_Del(self);
}

static PyTypeObject TrePatternType = {
  PyObject_HEAD_INIT(NULL)
  0,			        /* ob_size */
  TRE_MODULE ".Pattern",	/* tp_name */
  sizeof(TrePatternObject),	/* tp_basicsize */
  0,			        /* tp_itemsize */
  /* methods */
  (destructor)PyTrePattern_dealloc, /*tp_dealloc*/
  0,				/* tp_print */
  0,				/* tp_getattr */
  0,				/* tp_setattr */
  0,				/* tp_compare */
  0,				/* tp_repr */
  0,				/* tp_as_number */
  0,				/* tp_as_sequence */
  0,				/* tp_as_mapping */
  0,				/* tp_hash */
  0,				/* tp_call */
  0,				/* tp_str */
  0,				/* tp_getattro */
  0,				/* tp_setattro */
  0,				/* tp_as_buffer */
  Py_TPFLAGS_DEFAULT,		/* tp_flags */
  TRE_MODULE ".pattern object holds compiled tre regex",	/* tp_doc */
  0,				/* tp_traverse */
  0,				/* tp_clear */
  0,				/* tp_richcompare */
  0,				/* tp_weaklistoffset */
  0,				/* tp_iter */
  0,				/* tp_iternext */
  TrePattern_methods,		/* tp_methods */
  TrePattern_members		/* tp_members */
};

static TrePatternObject *
newTrePatternObject(PyObject *args)
{
  TrePatternObject *self;

  self = PyObject_New(TrePatternObject, &TrePatternType);
  if (self == NULL)
    return NULL;
  self->flags = 0;
  return self;
}

static PyObject *
PyTre_ncompile(PyObject *self, PyObject *args)
{
  TrePatternObject *rv;
  char *pattern;
  size_t pattlen;
  int cflags = 0;
  int rc;

  if (!PyArg_ParseTuple(args, "s#|i:compile", &pattern, &pattlen, &cflags))
    return NULL;

  rv = newTrePatternObject(args);
  if (rv == NULL)
    return NULL;

  rc = regncomp(&rv->rgx, (char*)pattern, pattlen, cflags);
  if (rc != REG_OK)
    {
      if (!PyErr_Occurred())
	_set_tre_err(rc, &rv->rgx);
      Py_DECREF(rv);
      return NULL;
    }
  rv->flags = cflags;
  return (PyObject*)rv;
}

static PyMethodDef tre_methods[] = {
  { "compile", PyTre_ncompile, METH_VARARGS,
    "Compile a regular expression pattern, returning a "
    TRE_MODULE ".pattern object" },
  { NULL, NULL }
};

static char *tre_doc =
"Python module for TRE library\n\nModule exports "
"the only function: compile";

static struct _tre_flags {
  char *name;
  int val;
} tre_flags[] = {
  { "EXTENDED", REG_EXTENDED },
  { "ICASE", REG_ICASE },
  { "NEWLINE", REG_NEWLINE },
  { "NOSUB", REG_NOSUB },
  { "LITERAL", REG_LITERAL },

  { "NOTBOL", REG_NOTBOL },
  { "NOTEOL", REG_NOTEOL },
  { NULL, 0 }
};

PyMODINIT_FUNC
inittre(void)
{
  PyObject *m;
  struct _tre_flags *fp;

  if (PyType_Ready(&TreFuzzynessType) < 0)
    return;
  if (PyType_Ready(&TreMatchType) < 0)
    return;
  if (PyType_Ready(&TrePatternType) < 0)
    return;

  /* Create the module and add the functions */
  m = Py_InitModule3(TRE_MODULE, tre_methods, tre_doc);
  if (m == NULL)
    return;

  Py_INCREF(&TreFuzzynessType);
  if (PyModule_AddObject(m, "Fuzzyness", (PyObject*)&TreFuzzynessType) < 0)
    return;
  Py_INCREF(&TreMatchType);
  if (PyModule_AddObject(m, "Match", (PyObject*)&TreMatchType) < 0)
    return;
  Py_INCREF(&TrePatternType);
  if (PyModule_AddObject(m, "Pattern", (PyObject*)&TrePatternType) < 0)
    return;
  ErrorObject = PyErr_NewException(TRE_MODULE ".Error", NULL, NULL);
  Py_INCREF(ErrorObject);
  if (PyModule_AddObject(m, "Error", ErrorObject) < 0)
    return;

  /* Insert the flags */
  for (fp = tre_flags; fp->name != NULL; fp++)
    if (PyModule_AddIntConstant(m, fp->name, fp->val) < 0)
      return;
}
