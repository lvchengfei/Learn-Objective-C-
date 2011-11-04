<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-file.m</title>
<style type="text/css">
.enscript-comment { font-style: italic; color: rgb(178,34,34); }
.enscript-function-name { font-weight: bold; color: rgb(0,0,255); }
.enscript-variable-name { font-weight: bold; color: rgb(184,134,11); }
.enscript-keyword { font-weight: bold; color: rgb(160,32,240); }
.enscript-reference { font-weight: bold; color: rgb(95,158,160); }
.enscript-string { font-weight: bold; color: rgb(188,143,143); }
.enscript-builtin { font-weight: bold; color: rgb(218,112,214); }
.enscript-type { font-weight: bold; color: rgb(34,139,34); }
.enscript-highlight { text-decoration: underline; color: 0; }
</style>
</head>
<body id="top">
<h1 style="margin:8px;" id="f1">objc-file.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
<hr/>
<div></div>
<pre>
/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code <span class="enscript-type">and</span>/<span class="enscript-type">or</span> Modifications of
 * Original Code as defined in <span class="enscript-type">and</span> that are subject to the Apple Public
 * Source License Version 1.1 (the &quot;License&quot;).  You may <span class="enscript-type">not</span> use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at <a href="http://www.apple.com/publicsource">http://www.apple.com/publicsource</a> <span class="enscript-type">and</span> read it before using
 * this file.
 * 
 * The Original Code <span class="enscript-type">and</span> <span class="enscript-type">all</span> software distributed under the License are
 * distributed on an &quot;AS IS&quot; basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.  Please see the
 * License <span class="enscript-keyword">for</span> the specific language governing rights <span class="enscript-type">and</span> limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
// Copyright 1988-1996 NeXT Software, Inc.

#<span class="enscript-keyword">if</span> defined(__APPLE__) &amp;&amp; defined(__MACH__)
#import &quot;objc-private.h&quot;
#import &lt;mach-o/ldsyms.h&gt;
#import &lt;mach-o/dyld.h&gt;
#include &lt;string.h&gt;
#include &lt;stdlib.h&gt;

#import &lt;crt_externs.h&gt;

/* prototype coming soon to &lt;mach-o/getsect.h&gt; */
extern <span class="enscript-type">char</span> *getsectdatafromheader(
    struct mach_header *mhp,
    <span class="enscript-type">char</span> *segname,
    <span class="enscript-type">char</span> *sectname,
    int *<span class="enscript-type">size</span>);

/* Returns an array of <span class="enscript-type">all</span> the objc headers in the executable
 * Caller is responsible <span class="enscript-keyword">for</span> freeing.
 */	
headerType **_getObjcHeaders()
{
  const struct mach_header **headers;
  headers = malloc(sizeof(struct mach_header *) * 2);
  headers<span class="enscript-type">[</span>0<span class="enscript-type">]</span> = (const struct mach_header *)_NSGetMachExecuteHeader();
  headers<span class="enscript-type">[</span>1<span class="enscript-type">]</span> = 0;
  <span class="enscript-keyword">return</span> (headerType**)headers;
}

Module _getObjcModules(headerType *head, int *nmodules)
{
  unsigned <span class="enscript-type">size</span>;
  void *mods = getsectdatafromheader((headerType *)head,
                                     SEG_OBJC,
				     SECT_OBJC_MODULES,
				     &amp;<span class="enscript-type">size</span>);
  *nmodules = <span class="enscript-type">size</span> / sizeof(struct objc_module);
  <span class="enscript-keyword">return</span> (Module)mods;
}

SEL *_getObjcMessageRefs(headerType *head, int *nmess)
{
  unsigned <span class="enscript-type">size</span>;
  void *refs = getsectdatafromheader ((headerType *)head,
				  SEG_OBJC, &quot;__message_refs&quot;, &amp;<span class="enscript-type">size</span>);
  *nmess = <span class="enscript-type">size</span> / sizeof(SEL);
  <span class="enscript-keyword">return</span> (SEL *)refs;
}

ProtocolTemplate *_getObjcProtocols(headerType *head, int *nprotos)
{
  unsigned <span class="enscript-type">size</span>;
  void *protos = getsectdatafromheader ((headerType *)head,
				 SEG_OBJC, &quot;__protocol&quot;, &amp;<span class="enscript-type">size</span>);
  *nprotos = <span class="enscript-type">size</span> / sizeof(ProtocolTemplate);
  <span class="enscript-keyword">return</span> (ProtocolTemplate *)protos;
}

NXConstantStringTemplate *_getObjcStringObjects(headerType *head, int *nstrs)
{
  *nstrs = 0;
  <span class="enscript-keyword">return</span> NULL;
}

Class *_getObjcClassRefs(headerType *head, int *nclasses)
{
  unsigned <span class="enscript-type">size</span>;
  void *classes = getsectdatafromheader ((headerType *)head,
				 SEG_OBJC, &quot;__cls_refs&quot;, &amp;<span class="enscript-type">size</span>);
  *nclasses = <span class="enscript-type">size</span> / sizeof(Class);
  <span class="enscript-keyword">return</span> (Class *)classes;
}

/* returns start of <span class="enscript-type">all</span> objective-c info <span class="enscript-type">and</span> the <span class="enscript-type">size</span> of the data */
void *_getObjcHeaderData(headerType *head, unsigned *<span class="enscript-type">size</span>)
{
  struct segment_command *sgp;
  unsigned long <span class="enscript-type">i</span>;
  
  sgp = (struct segment_command *) ((<span class="enscript-type">char</span> *)head + sizeof(headerType));
  <span class="enscript-keyword">for</span>(<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; ((headerType *)head)-&gt;ncmds; <span class="enscript-type">i</span>++){
      <span class="enscript-keyword">if</span>(sgp-&gt;cmd == LC_SEGMENT)
	  <span class="enscript-keyword">if</span>(<span class="enscript-type">strncmp</span>(sgp-&gt;segname, &quot;__OBJC&quot;, sizeof(sgp-&gt;segname)) == 0) {
	    *<span class="enscript-type">size</span> = sgp-&gt;filesize;
	    <span class="enscript-keyword">return</span> (void*)sgp;
	    }
      sgp = (struct segment_command *)((<span class="enscript-type">char</span> *)sgp + sgp-&gt;cmdsize);
  }
  *<span class="enscript-type">size</span> = 0;
  <span class="enscript-keyword">return</span> nil;
}

static const headerType *_getExecHeader (void)
{
	<span class="enscript-keyword">return</span> (const struct mach_header *)_NSGetMachExecuteHeader();
}

const <span class="enscript-type">char</span> *_getObjcHeaderName(headerType *header)
{
    const headerType *execHeader;
    const struct fvmlib_command *libCmd, *endOfCmds;
    <span class="enscript-type">char</span> **argv;
#<span class="enscript-keyword">if</span> !defined(NeXT_PDO)
    extern <span class="enscript-type">char</span> ***_NSGetArgv();
    argv = *_NSGetArgv();
#<span class="enscript-keyword">else</span>
    extern <span class="enscript-type">char</span> **NXArgv;
    argv = NXArgv;
#endif
       
    <span class="enscript-keyword">if</span> (header &amp;&amp; ((headerType *)header)-&gt;filetype == MH_FVMLIB) {
	    execHeader = _getExecHeader();
	    <span class="enscript-keyword">for</span> (libCmd = (const struct fvmlib_command *)(execHeader + 1),
		  endOfCmds = ((void *)libCmd) + execHeader-&gt;sizeofcmds;
		  libCmd &lt; endOfCmds; ((void *)libCmd) += libCmd-&gt;cmdsize) {
		    <span class="enscript-keyword">if</span> ((libCmd-&gt;cmd == LC_LOADFVMLIB) &amp;&amp; (libCmd-&gt;fvmlib.header_addr
			    == (unsigned long)header)) {
			    <span class="enscript-keyword">return</span> (<span class="enscript-type">char</span> *)libCmd
				    + libCmd-&gt;fvmlib.name.offset;
		    }
	    }
	    <span class="enscript-keyword">return</span> NULL;
   } <span class="enscript-keyword">else</span> {
      unsigned long <span class="enscript-type">i</span>, n = _dyld_image_count();
      <span class="enscript-keyword">for</span>( <span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; n ; <span class="enscript-type">i</span>++ ) {
         <span class="enscript-keyword">if</span> ( _dyld_get_image_header(<span class="enscript-type">i</span>) == header )
            <span class="enscript-keyword">return</span> _dyld_get_image_name(<span class="enscript-type">i</span>);
      }
      <span class="enscript-keyword">return</span> argv<span class="enscript-type">[</span>0<span class="enscript-type">]</span>;
   }
}

#elif defined(hpux) || defined(__hpux__)

/* 
 *      Objective-C runtime information module.
 *      This module is specific to hp-ux a.out <span class="enscript-type">format</span> files.
 */

#import &lt;pdo.h&gt;	// place where padding_bug would be
#include &lt;a.out.h&gt;
#include &quot;objc-private.h&quot;

OBJC_EXPORT int __argc_value;
OBJC_EXPORT <span class="enscript-type">char</span> **__argv_value;
int NXArgc = 0;
<span class="enscript-type">char</span> **NXArgv = NULL;

OBJC_EXPORT unsigned SEG_OBJC_CLASS_START;
OBJC_EXPORT unsigned SEG_OBJC_METACLASS_START;
OBJC_EXPORT unsigned SEG_OBJC_CAT_CLS_METH_START;
OBJC_EXPORT unsigned SEG_OBJC_CAT_INST_METH_START;
OBJC_EXPORT unsigned SEG_OBJC_CLS_METH_START;
OBJC_EXPORT unsigned SEG_OBJC_INST_METHODS_START;
OBJC_EXPORT unsigned SEG_OBJC_MESSAGE_REFS_START;
OBJC_EXPORT unsigned SEG_OBJC_SYMBOLS_START;
OBJC_EXPORT unsigned SEG_OBJC_CATEGORY_START;
OBJC_EXPORT unsigned SEG_OBJC_PROTOCOL_START;
OBJC_EXPORT unsigned SEG_OBJC_CLASS_VARS_START;
OBJC_EXPORT unsigned SEG_OBJC_INSTANCE_VARS_START;
OBJC_EXPORT unsigned SEG_OBJC_MODULES_START;
OBJC_EXPORT unsigned SEG_OBJC_STRING_OBJECT_START;
OBJC_EXPORT unsigned SEG_OBJC_CLASS_NAMES_START;
OBJC_EXPORT unsigned SEG_OBJC_METH_VAR_NAMES_START;
OBJC_EXPORT unsigned SEG_OBJC_METH_VAR_TYPES_START;
OBJC_EXPORT unsigned SEG_OBJC_CLS_REFS_START;

OBJC_EXPORT unsigned SEG_OBJC_CLASS_END;
OBJC_EXPORT unsigned SEG_OBJC_METACLASS_END;
OBJC_EXPORT unsigned SEG_OBJC_CAT_CLS_METH_END;
OBJC_EXPORT unsigned SEG_OBJC_CAT_INST_METH_END;
OBJC_EXPORT unsigned SEG_OBJC_CLS_METH_END;
OBJC_EXPORT unsigned SEG_OBJC_INST_METHODS_END;
OBJC_EXPORT unsigned SEG_OBJC_MESSAGE_REFS_END;
OBJC_EXPORT unsigned SEG_OBJC_SYMBOLS_END;
OBJC_EXPORT unsigned SEG_OBJC_CATEGORY_END;
OBJC_EXPORT unsigned SEG_OBJC_PROTOCOL_END;
OBJC_EXPORT unsigned SEG_OBJC_CLASS_VARS_END;
OBJC_EXPORT unsigned SEG_OBJC_INSTANCE_VARS_END;
OBJC_EXPORT unsigned SEG_OBJC_MODULES_END;
OBJC_EXPORT unsigned SEG_OBJC_STRING_OBJECT_END;
OBJC_EXPORT unsigned SEG_OBJC_CLASS_NAMES_END;
OBJC_EXPORT unsigned SEG_OBJC_METH_VAR_NAMES_END;
OBJC_EXPORT unsigned SEG_OBJC_METH_VAR_TYPES_END;
OBJC_EXPORT unsigned SEG_OBJC_CLS_REFS_END;

typedef struct	_simple_header_struct {
	<span class="enscript-type">char</span> * 	subspace_name	;
	void *	start_address	;
	void *	end_address	;
	} simple_header_struct ;

static simple_header_struct our_objc_header<span class="enscript-type">[</span><span class="enscript-type">]</span> = {
	{ &quot;$$OBJC_CLASS$$&quot;, 		&amp;SEG_OBJC_CLASS_START, 		&amp;SEG_OBJC_CLASS_END },
	{ &quot;$$OBJC_METACLASS$$&quot;, 	&amp;SEG_OBJC_METACLASS_START, 	&amp;SEG_OBJC_METACLASS_END },
	{ &quot;$$OBJC_CAT_CLS_METH$$&quot;,	&amp;SEG_OBJC_CAT_CLS_METH_START, 	&amp;SEG_OBJC_CAT_CLS_METH_END },
	{ &quot;$$OBJC_CAT_INST_METH$$&quot;, 	&amp;SEG_OBJC_CAT_INST_METH_START, 	&amp;SEG_OBJC_CAT_INST_METH_END },
	{ &quot;$$OBJC_CLS_METH$$&quot;, 		&amp;SEG_OBJC_CLS_METH_START, 	&amp;SEG_OBJC_CLS_METH_END },
	{ &quot;$$OBJC_INST_METHODS$$&quot;,	&amp;SEG_OBJC_INST_METHODS_START, 	&amp;SEG_OBJC_INST_METHODS_END },
	{ &quot;$$OBJC_MESSAGE_REFS$$&quot;,	&amp;SEG_OBJC_MESSAGE_REFS_START, 	&amp;SEG_OBJC_MESSAGE_REFS_END },
	{ &quot;$$OBJC_SYMBOLS$$&quot;, 		&amp;SEG_OBJC_SYMBOLS_START, 	&amp;SEG_OBJC_SYMBOLS_END },
	{ &quot;$$OBJC_CATEGORY$$&quot;, 		&amp;SEG_OBJC_CATEGORY_START, 	&amp;SEG_OBJC_CATEGORY_END },
	{ &quot;$$OBJC_PROTOCOL$$&quot;, 		&amp;SEG_OBJC_PROTOCOL_START, 	&amp;SEG_OBJC_PROTOCOL_END },
	{ &quot;$$OBJC_CLASS_VARS$$&quot;, 	&amp;SEG_OBJC_CLASS_VARS_START, 	&amp;SEG_OBJC_CLASS_VARS_END },
	{ &quot;$$OBJC_INSTANCE_VARS$$&quot;, 	&amp;SEG_OBJC_INSTANCE_VARS_START, 	&amp;SEG_OBJC_INSTANCE_VARS_END },
	{ &quot;$$OBJC_MODULES$$&quot;, 		&amp;SEG_OBJC_MODULES_START, 	&amp;SEG_OBJC_MODULES_END },
	{ &quot;$$OBJC_STRING_OBJECT$$&quot;, 	&amp;SEG_OBJC_STRING_OBJECT_START, 	&amp;SEG_OBJC_STRING_OBJECT_END },
	{ &quot;$$OBJC_CLASS_NAMES$$&quot;, 	&amp;SEG_OBJC_CLASS_NAMES_START, 	&amp;SEG_OBJC_CLASS_NAMES_END },
	{ &quot;$$OBJC_METH_VAR_NAMES$$&quot;, 	&amp;SEG_OBJC_METH_VAR_TYPES_START, &amp;SEG_OBJC_METH_VAR_NAMES_END },
	{ &quot;$$OBJC_METH_VAR_TYPES$$&quot;,	&amp;SEG_OBJC_METH_VAR_TYPES_START, &amp;SEG_OBJC_METH_VAR_TYPES_END },
	{ &quot;$$OBJC_CLS_REFS$$&quot;, 		&amp;SEG_OBJC_CLS_REFS_START, 	&amp;SEG_OBJC_CLS_REFS_END },
	{ NULL, NULL, NULL }
	};

/* Returns an array of <span class="enscript-type">all</span> the objc headers in the executable (<span class="enscript-type">and</span> shlibs)
 * Caller is responsible <span class="enscript-keyword">for</span> freeing.
 */
headerType **_getObjcHeaders()
{

  /* Will need to <span class="enscript-type">fill</span> in with <span class="enscript-type">any</span> shlib info later as well.  Need <span class="enscript-type">more</span>
   * info on this.
   */
  
  /*
   *	this is truly ugly, hpux does <span class="enscript-type">not</span> map in the header so we have to
   * 	<span class="enscript-type">try</span> <span class="enscript-type">and</span> <span class="enscript-type">find</span> it <span class="enscript-type">and</span> map it in.  their crt0 has some <span class="enscript-type">global</span> vars
   *    that <span class="enscript-type">hold</span> argv<span class="enscript-type">[</span>0<span class="enscript-type">]</span> <span class="enscript-type">which</span> we will use to <span class="enscript-type">find</span> the executable file
   */

  headerType **hdrs = (headerType**)malloc(2 * sizeof(headerType*));
  NXArgv = __argv_value;
  NXArgc = __argc_value;
  hdrs<span class="enscript-type">[</span>0<span class="enscript-type">]</span> = &amp;our_objc_header;
  hdrs<span class="enscript-type">[</span>1<span class="enscript-type">]</span> = 0;
  <span class="enscript-keyword">return</span> hdrs;
}

// I think we are getting the address of the table (ie the table itself) 
//	isn<span class="enscript-keyword">'</span>t that expensive ?
static void *getsubspace(headerType *objchead, <span class="enscript-type">char</span> *sname, unsigned *<span class="enscript-type">size</span>)
{
	simple_header_struct *table = (simple_header_struct *)objchead;
	int <span class="enscript-type">i</span> = 0;

	<span class="enscript-keyword">while</span> (  table<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.subspace_name){
		<span class="enscript-keyword">if</span> (!<span class="enscript-type">strcmp</span>(table<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.subspace_name, sname)){
			*<span class="enscript-type">size</span> = table<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.end_address - table<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.start_address;
			<span class="enscript-keyword">return</span> table<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>.start_address;
		}
		<span class="enscript-type">i</span>++;
	}
	*<span class="enscript-type">size</span> = 0;
	<span class="enscript-keyword">return</span> nil;
}

Module _getObjcModules(headerType *head, int *nmodules)
{
  unsigned <span class="enscript-type">size</span>;
  void *mods = getsubspace(head,&quot;$$OBJC_MODULES$$&quot;,&amp;<span class="enscript-type">size</span>);
  *nmodules = <span class="enscript-type">size</span> / sizeof(struct objc_module);
  <span class="enscript-keyword">return</span> (Module)mods;
}

SEL *_getObjcMessageRefs(headerType *head, int *nmess)
{
  unsigned <span class="enscript-type">size</span>;
  void *refs = getsubspace (head,&quot;$$OBJC_MESSAGE_REFS$$&quot;, &amp;<span class="enscript-type">size</span>);
  *nmess = <span class="enscript-type">size</span> / sizeof(SEL);
  <span class="enscript-keyword">return</span> (SEL *)refs;
}

struct proto_template *_getObjcProtocols(headerType *head, int *nprotos)
{
  unsigned <span class="enscript-type">size</span>;
  <span class="enscript-type">char</span> *p;
  <span class="enscript-type">char</span> *<span class="enscript-keyword">end</span>;
  <span class="enscript-type">char</span> *start;

  start = getsubspace (head,&quot;$$OBJC_PROTOCOL$$&quot;, &amp;<span class="enscript-type">size</span>);

#ifdef PADDING_BUG
  /*
   * XXX: Look <span class="enscript-keyword">for</span> padding of 4 zero bytes <span class="enscript-type">and</span> remove it.
   * XXX: Depends upon first four bytes of a proto_template never being 0.
   * XXX: Somebody should check to see <span class="enscript-keyword">if</span> this is really the <span class="enscript-type">case</span>.
   */
  <span class="enscript-keyword">end</span> = start + <span class="enscript-type">size</span>;
  <span class="enscript-keyword">for</span> (p = start; p &lt; <span class="enscript-keyword">end</span>; p += sizeof(struct proto_template)) {
      <span class="enscript-keyword">if</span> (!p<span class="enscript-type">[</span>0<span class="enscript-type">]</span> &amp;&amp; !p<span class="enscript-type">[</span>1<span class="enscript-type">]</span> &amp;&amp; !p<span class="enscript-type">[</span>2<span class="enscript-type">]</span> &amp;&amp; !p<span class="enscript-type">[</span>3<span class="enscript-type">]</span>) {
          memcpy(p, p + sizeof(long), (<span class="enscript-keyword">end</span> - p) - sizeof(long));
          <span class="enscript-keyword">end</span> -= sizeof(long);
      }
  }
  <span class="enscript-type">size</span> = <span class="enscript-keyword">end</span> - start;
#endif
  *nprotos = <span class="enscript-type">size</span> / sizeof(struct proto_template);
  <span class="enscript-keyword">return</span> ((struct proto_template *)start);
}

NXConstantStringTemplate *_getObjcStringObjects(headerType *head, int *nstrs)
{
  unsigned <span class="enscript-type">size</span>;
  void *str = getsubspace (head,&quot;$$OBJC_STRING_OBJECT$$&quot;, &amp;<span class="enscript-type">size</span>);
  *nstrs = <span class="enscript-type">size</span> / sizeof(NXConstantStringTemplate);
  <span class="enscript-keyword">return</span> (NXConstantStringTemplate *)str;
}

Class *_getObjcClassRefs(headerType *head, int *nclasses)
{
  unsigned <span class="enscript-type">size</span>;
  void *classes = getsubspace (head,&quot;$$OBJC_CLS_REFS$$&quot;, &amp;<span class="enscript-type">size</span>);
  *nclasses = <span class="enscript-type">size</span> / sizeof(Class);
  <span class="enscript-keyword">return</span> (Class *)classes;
}

/* returns start of <span class="enscript-type">all</span> objective-c info <span class="enscript-type">and</span> the <span class="enscript-type">size</span> of the data */
void *_getObjcHeaderData(headerType *head, unsigned *<span class="enscript-type">size</span>)
{
#<span class="enscript-type">warning</span> _getObjcHeaderData <span class="enscript-type">not</span> implemented yet
  *<span class="enscript-type">size</span> = 0;
  <span class="enscript-keyword">return</span> nil;
}


const <span class="enscript-type">char</span> *_getObjcHeaderName(headerType *header)
{
  <span class="enscript-keyword">return</span> &quot;oh poo&quot;;
}

#<span class="enscript-keyword">else</span>

/* 
 *      Objective-C runtime information module.
 *      This module is generic <span class="enscript-keyword">for</span> <span class="enscript-type">all</span> object <span class="enscript-type">format</span> files.
 */

#import &lt;pdo.h&gt;
#import &lt;Protocol.h&gt;
#import &quot;objc-private.h&quot;
#<span class="enscript-keyword">if</span> defined(WIN32)
    #import &lt;stdlib.h&gt;
#endif

int		NXArgc = 0;
<span class="enscript-type">char</span>	**	NXArgv = NULL;


<span class="enscript-type">char</span> ***_NSGetArgv(void)
{
	<span class="enscript-keyword">return</span> &amp;NXArgv;
}

int *_NSGetArgc(void)
{
	<span class="enscript-keyword">return</span> &amp;NXArgc;

}

#<span class="enscript-keyword">if</span> defined(WIN32)
    OBJC_EXPORT <span class="enscript-type">char</span> ***_environ_dll;
#elif defined(NeXT_PDO)
    OBJC_EXPORT <span class="enscript-type">char</span> ***environ;
#endif

<span class="enscript-type">char</span> ***_NSGetEnviron(void)
{
#<span class="enscript-keyword">if</span> defined(WIN32)
	<span class="enscript-keyword">return</span> (<span class="enscript-type">char</span> ***)_environ_dll;
#elif defined(NeXT_PDO)
	<span class="enscript-keyword">return</span> (<span class="enscript-type">char</span> ***)&amp;environ;
#<span class="enscript-keyword">else</span>
        #<span class="enscript-type">warning</span> &quot;_NSGetEnviron() is unimplemented <span class="enscript-keyword">for</span> this architecture&quot;
	<span class="enscript-keyword">return</span> (<span class="enscript-type">char</span> ***)NULL;
#endif
}


#<span class="enscript-keyword">if</span> !defined(__hpux__) &amp;&amp; !defined(hpux) &amp;&amp; !defined(__osf__) 
    const <span class="enscript-type">char</span> OBJC_METH_VAR_NAME_FORWARD<span class="enscript-type">[</span>10<span class="enscript-type">]</span>=&quot;forward::&quot;;
#<span class="enscript-keyword">else</span>
    OBJC_EXPORT <span class="enscript-type">char</span> OBJC_METH_VAR_NAME_FORWARD<span class="enscript-type">[</span><span class="enscript-type">]</span>;
#endif

static objcSectionStruct objcHeaders = {0,0,sizeof(objcModHeader)};
objcModHeader *CMH = 0;  // Current Module Header

int _objcModuleCount() {
   <span class="enscript-keyword">return</span> objcHeaders.count;
}

const <span class="enscript-type">char</span> *_objcModuleNameAtIndex(int <span class="enscript-type">i</span>) {
   <span class="enscript-keyword">if</span> ( <span class="enscript-type">i</span> &lt; 0 || <span class="enscript-type">i</span> &gt;= objcHeaders.count)
      <span class="enscript-keyword">return</span> NULL;
   <span class="enscript-keyword">return</span> ((objcModHeader*)objcHeaders.data + <span class="enscript-type">i</span>)-&gt;name;
}

static <span class="enscript-type">inline</span> void allocElements (objcSectionStruct *ptr, int nelmts)
{
    <span class="enscript-keyword">if</span> (ptr-&gt;data == 0) {
        ptr-&gt;data = (void*)malloc ((ptr-&gt;count+nelmts) * ptr-&gt;<span class="enscript-type">size</span>);
    } <span class="enscript-keyword">else</span> {
        volatile void *tempData = (void *)realloc(ptr-&gt;data, (ptr-&gt;count+nelmts) * ptr-&gt;<span class="enscript-type">size</span>);
        ptr-&gt;data = (void **)tempData;
    }

    bzero((<span class="enscript-type">char</span>*)ptr-&gt;data + ptr-&gt;count * ptr-&gt;<span class="enscript-type">size</span>, ptr-&gt;<span class="enscript-type">size</span> * nelmts);
}

OBJC_EXPORT void _objcInit(void);
void objc_finish_header (void)
{
     _objcInit ();
     CMH = (objcModHeader *)0;
     // leaking like a stuck pig.
}

void objc_register_header_name (const <span class="enscript-type">char</span> * name) {
    <span class="enscript-keyword">if</span> (name) {
        CMH-&gt;name = malloc(strlen(name)+1);
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
		bzero(CMH-&gt;name, (strlen(name)+1));
#endif 
        strcpy(CMH-&gt;name, name);
    }
}

void objc_register_header (const <span class="enscript-type">char</span> * name)
{
    <span class="enscript-keyword">if</span> (CMH) {
      	// we<span class="enscript-keyword">'</span>ve already registered a header (probably via __objc_execClass), 
	// so just update the name.
       <span class="enscript-keyword">if</span> (CMH-&gt;name)
         free(CMH-&gt;name);
    } <span class="enscript-keyword">else</span> {
        allocElements (&amp;objcHeaders, 1);
        CMH = (objcModHeader *)objcHeaders.data + objcHeaders.count;
        objcHeaders.count++;
        bzero(CMH, sizeof(objcModHeader));

        CMH-&gt;Modules.<span class="enscript-type">size</span>       = sizeof(struct objc_module);
        CMH-&gt;Classes.<span class="enscript-type">size</span>       = sizeof(void *);
        CMH-&gt;Protocols.<span class="enscript-type">size</span>     = sizeof(void *);
        CMH-&gt;StringObjects.<span class="enscript-type">size</span> = sizeof(void *);
    }
    objc_register_header_name(name);
}

#<span class="enscript-keyword">if</span> defined(DEBUG)
void printModule(Module <span class="enscript-type">mod</span>)
{
    printf(&quot;name=\&quot;<span class="enscript-comment">%s\&quot;, symtab=%x\n&quot;, mod-&gt;name, mod-&gt;symtab);
</span>}

void dumpModules(void)
{
    int <span class="enscript-type">i</span>,<span class="enscript-type">j</span>;
    Module <span class="enscript-type">mod</span>;
    objcModHeader *cmh;

    printf(&quot;dumpModules(): found <span class="enscript-comment">%d header(s)\n&quot;, objcHeaders.count);
</span>    <span class="enscript-keyword">for</span> (<span class="enscript-type">j</span>=0; <span class="enscript-type">j</span>&lt;objcHeaders.count; ++<span class="enscript-type">j</span>) {
	        cmh = (objcModHeader *)objcHeaders.data + <span class="enscript-type">j</span>;

	printf(&quot;===<span class="enscript-comment">%s, found %d modules\n&quot;, cmh-&gt;name, cmh-&gt;Modules.count);
</span>

	<span class="enscript-type">mod</span> = (Module)cmh-&gt;Modules.data;
    
	<span class="enscript-keyword">for</span> (<span class="enscript-type">i</span>=0; <span class="enscript-type">i</span>&lt;cmh-&gt;Modules.count; <span class="enscript-type">i</span>++) {
		    printf(&quot;\tname=\&quot;<span class="enscript-comment">%s\&quot;, symtab=%x, sel_ref_cnt=%d\n&quot;, mod-&gt;name, mod-&gt;symtab, (Symtab)(mod-&gt;symtab)-&gt;sel_ref_cnt);
</span>	    <span class="enscript-type">mod</span>++;
	}
    }
}
#endif  // DEBUG

static <span class="enscript-type">inline</span> void addObjcProtocols(struct objc_protocol_list * pl)
{
   <span class="enscript-keyword">if</span> ( !pl )
      <span class="enscript-keyword">return</span>;
   <span class="enscript-keyword">else</span> {
      int count = 0;
      struct objc_protocol_list *list = pl;
      <span class="enscript-keyword">while</span> ( list ) {
         count += list-&gt;count;
         list = list-&gt;next;
      }
      allocElements( &amp;CMH-&gt;Protocols, count );

      list = pl;
      <span class="enscript-keyword">while</span> ( list ) {
         int <span class="enscript-type">i</span> = 0;
         <span class="enscript-keyword">while</span> ( <span class="enscript-type">i</span> &lt; list-&gt;count )
            CMH-&gt;Protocols.data<span class="enscript-type">[</span> CMH-&gt;Protocols.count++ <span class="enscript-type">]</span> = (void*) list-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span>++<span class="enscript-type">]</span>;
         list = list-&gt;next;
      }

      list = pl;
      <span class="enscript-keyword">while</span> ( list ) {
         int <span class="enscript-type">i</span> = 0;
         <span class="enscript-keyword">while</span> ( <span class="enscript-type">i</span> &lt; list-&gt;count )
            addObjcProtocols( ((ProtocolTemplate*)list-&gt;list<span class="enscript-type">[</span><span class="enscript-type">i</span>++<span class="enscript-type">]</span>)-&gt;protocol_list );
         list = list-&gt;next;
      }
   }
}

static void
_parseObjcModule(struct objc_symtab *symtab)
{
    int <span class="enscript-type">i</span>=0, <span class="enscript-type">j</span>=0, k;
    SEL *refs = symtab-&gt;refs, sel;


    // Add the selector references

    <span class="enscript-keyword">if</span> (refs)
    {
        symtab-&gt;sel_ref_cnt = 0;

        <span class="enscript-keyword">while</span> (*refs)
        {
            symtab-&gt;sel_ref_cnt++;
            // don<span class="enscript-keyword">'</span>t touvh the VM page <span class="enscript-keyword">if</span> <span class="enscript-type">not</span> necessary
            <span class="enscript-keyword">if</span> ( (sel = sel_registerNameNoCopy ((const <span class="enscript-type">char</span> *)*refs)) != *refs ) {
                *refs = sel;
            }
            refs++;
        }
    }

    // Walk through <span class="enscript-type">all</span> of the ObjC Classes

    <span class="enscript-keyword">if</span> ((k = symtab-&gt;cls_def_cnt))
      {
	allocElements (&amp;CMH-&gt;Classes, k);

	<span class="enscript-keyword">for</span> ( <span class="enscript-type">i</span>=0, <span class="enscript-type">j</span> = symtab-&gt;cls_def_cnt; <span class="enscript-type">i</span> &lt; <span class="enscript-type">j</span>; <span class="enscript-type">i</span>++ )
	  {
	    struct objc_class       *<span class="enscript-type">class</span>;
 	    unsigned loop;
	    
	    <span class="enscript-type">class</span>  = (struct objc_class *)symtab-&gt;defs<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
	    objc_addClass(<span class="enscript-type">class</span>);
	    CMH-&gt;Classes.data<span class="enscript-type">[</span> CMH-&gt;Classes.count++ <span class="enscript-type">]</span> = (void*) <span class="enscript-type">class</span>-&gt;name;
	    addObjcProtocols (<span class="enscript-type">class</span>-&gt;protocols);

            // ignore fixing up the selectors to be <span class="enscript-type">unique</span> (<span class="enscript-keyword">for</span> <span class="enscript-type">now</span>; done lazily later)

	  }
      }

    // Walk through <span class="enscript-type">all</span> of the ObjC Categories

    <span class="enscript-keyword">if</span> ((k = symtab-&gt;cat_def_cnt))
      {
	allocElements (&amp;CMH-&gt;Classes, k);

	<span class="enscript-keyword">for</span> ( <span class="enscript-type">j</span> += symtab-&gt;cat_def_cnt;
	     <span class="enscript-type">i</span> &lt; <span class="enscript-type">j</span>;
	     <span class="enscript-type">i</span>++ )
	  {
	    struct objc_category       *category;
	    
	    category  = (struct objc_category *)symtab-&gt;defs<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
	    CMH-&gt;Classes.data<span class="enscript-type">[</span> CMH-&gt;Classes.count++ <span class="enscript-type">]</span> = 
		(void*) category-&gt;class_name;

	    addObjcProtocols (category-&gt;protocols);

            // ignore fixing the selectors to be <span class="enscript-type">unique</span>
            // this is <span class="enscript-type">now</span> done lazily upon use
	    //_objc_inlined_fixup_selectors_in_method_list(category-&gt;instance_methods);
	    //_objc_inlined_fixup_selectors_in_method_list(category-&gt;class_methods);
	  }
      }


    // Walk through <span class="enscript-type">all</span> of the ObjC Static Strings

    <span class="enscript-keyword">if</span> ((k = symtab-&gt;obj_defs))
      {
	allocElements (&amp;CMH-&gt;StringObjects, k);

	<span class="enscript-keyword">for</span> ( <span class="enscript-type">j</span> += symtab-&gt;obj_defs;
	     <span class="enscript-type">i</span> &lt; <span class="enscript-type">j</span>;
	     <span class="enscript-type">i</span>++ )
	  {
	    NXConstantStringTemplate *string = ( NXConstantStringTemplate *)symtab-&gt;defs<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
	    CMH-&gt;StringObjects.data<span class="enscript-type">[</span> CMH-&gt;StringObjects.count++ <span class="enscript-type">]</span> = 
		(void*) string;
	  }
      }

    // Walk through <span class="enscript-type">all</span> of the ObjC Static Protocols

    <span class="enscript-keyword">if</span> ((k = symtab-&gt;proto_defs))
      {
	allocElements (&amp;CMH-&gt;Protocols, k);

	<span class="enscript-keyword">for</span> ( <span class="enscript-type">j</span> += symtab-&gt;proto_defs;
	     <span class="enscript-type">i</span> &lt; <span class="enscript-type">j</span>;
	     <span class="enscript-type">i</span>++ )
	  {
	    ProtocolTemplate *proto = ( ProtocolTemplate *)symtab-&gt;defs<span class="enscript-type">[</span><span class="enscript-type">i</span><span class="enscript-type">]</span>;
            allocElements (&amp;CMH-&gt;Protocols, 1);
	    CMH-&gt;Protocols.data<span class="enscript-type">[</span> CMH-&gt;Protocols.count++ <span class="enscript-type">]</span> = 
		(void*) proto;

	    addObjcProtocols(proto-&gt;protocol_list);
	  }
      }
}

// used only as a dll initializer on Windows <span class="enscript-type">and</span>/<span class="enscript-type">or</span> hppa (!)
void __objc_execClass(Module <span class="enscript-type">mod</span>)
{
    sel_registerName ((const <span class="enscript-type">char</span> *)OBJC_METH_VAR_NAME_FORWARD);

    <span class="enscript-keyword">if</span> (CMH == 0) {
	    objc_register_header(NXArgv ? NXArgv<span class="enscript-type">[</span>0<span class="enscript-type">]</span> : &quot;&quot;);
    }

    allocElements (&amp;CMH-&gt;Modules, 1);

    memcpy( (Module)CMH-&gt;Modules.data 
                  + CMH-&gt;Modules.count,
	    <span class="enscript-type">mod</span>,
	    sizeof(struct objc_module));
    CMH-&gt;Modules.count++;

    _parseObjcModule(<span class="enscript-type">mod</span>-&gt;symtab);
}

const <span class="enscript-type">char</span> * NSModulePathForClass(Class cls)
{
#<span class="enscript-keyword">if</span> defined(WIN32)
    int <span class="enscript-type">i</span>, <span class="enscript-type">j</span>, k;

    <span class="enscript-keyword">for</span> (<span class="enscript-type">i</span> = 0; <span class="enscript-type">i</span> &lt; objcHeaders.count; <span class="enscript-type">i</span>++) {
	volatile objcModHeader *aHeader = (objcModHeader *)objcHeaders.data + <span class="enscript-type">i</span>;
	<span class="enscript-keyword">for</span> (<span class="enscript-type">j</span> = 0; <span class="enscript-type">j</span> &lt; aHeader-&gt;Modules.count; <span class="enscript-type">j</span>++) {
	    Module <span class="enscript-type">mod</span> = (void *)(aHeader-&gt;Modules.data) + <span class="enscript-type">j</span> * aHeader-&gt;Modules.<span class="enscript-type">size</span>;
	    struct objc_symtab *symtab = <span class="enscript-type">mod</span>-&gt;symtab;
	    <span class="enscript-keyword">for</span> (k = 0; k &lt; symtab-&gt;cls_def_cnt; k++) {
		<span class="enscript-keyword">if</span> (cls == (Class)symtab-&gt;defs<span class="enscript-type">[</span>k<span class="enscript-type">]</span>)
		    <span class="enscript-keyword">return</span> aHeader-&gt;name;
	    }
	}
    }
#<span class="enscript-keyword">else</span>
    #<span class="enscript-type">warning</span> &quot;NSModulePathForClass is <span class="enscript-type">not</span> fully implemented!&quot;
#endif
    <span class="enscript-keyword">return</span> NULL;
}

unsigned int _objc_goff_headerCount (void)
{
    <span class="enscript-keyword">return</span> objcHeaders.count;
}

/* Build the header vector, of <span class="enscript-type">all</span> headers seen so far. */

struct header_info *_objc_goff_headerVector ()
{
  unsigned int hidx;
  struct header_info *hdrVec;

  hdrVec = malloc_zone_malloc (_objc_create_zone(),
                         objcHeaders.count * sizeof (struct header_info));
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
  bzero(hdrVec, (objcHeaders.count * sizeof (struct header_info)));
#endif

  <span class="enscript-keyword">for</span> (hidx = 0; hidx &lt; objcHeaders.count; hidx++)
    {
      objcModHeader *aHeader = (objcModHeader *)objcHeaders.data + hidx;
 
      hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mhdr = (headerType**) aHeader;
      hdrVec<span class="enscript-type">[</span>hidx<span class="enscript-type">]</span>.mod_ptr = (Module)(aHeader-&gt;Modules.data);
    }
  <span class="enscript-keyword">return</span> hdrVec;
}


#<span class="enscript-keyword">if</span> defined(sparc)
    int __NXArgc = 0;
    <span class="enscript-type">char</span> ** __NXArgv = 0;  
#endif 

/* Returns an array of <span class="enscript-type">all</span> the objc headers in the executable (<span class="enscript-type">and</span> shlibs)
 * Caller is responsible <span class="enscript-keyword">for</span> freeing.
 */
headerType **_getObjcHeaders()
{
								   
#<span class="enscript-keyword">if</span> defined(__hpux__) || defined(hpux)
    OBJC_EXPORT int __argc_value;
    OBJC_EXPORT <span class="enscript-type">char</span> ** __argv_value;
#endif

  /* Will need to <span class="enscript-type">fill</span> in with <span class="enscript-type">any</span> shlib info later as well.  Need <span class="enscript-type">more</span>
   * info on this.
   */
  
  headerType **hdrs = (headerType**)malloc(2 * sizeof(headerType*));
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__)
  bzero(hdrs, (2 * sizeof(headerType*)));
#endif
#<span class="enscript-keyword">if</span> defined(__hpux__) || defined(hpux)
  NXArgv = __argv_value;
  NXArgc = __argc_value;
#<span class="enscript-keyword">else</span> /* __hpux__ || hpux */
#<span class="enscript-keyword">if</span> defined(sparc) 
  NXArgv = __NXArgv;
  NXArgc = __NXArgc;
#endif /* sparc */
#endif /* __hpux__ || hpux */

  hdrs<span class="enscript-type">[</span>0<span class="enscript-type">]</span> = (headerType*)CMH;
  hdrs<span class="enscript-type">[</span>1<span class="enscript-type">]</span> = 0;
  <span class="enscript-keyword">return</span> hdrs;
}

static objcModHeader *_getObjcModHeader(headerType *head)
{
	<span class="enscript-keyword">return</span> (objcModHeader *)head;
}
 
Module _getObjcModules(headerType *head, int *<span class="enscript-type">size</span>)
{
    objcModHeader *modHdr = _getObjcModHeader(head);
    <span class="enscript-keyword">if</span> (modHdr) {
	*<span class="enscript-type">size</span> = modHdr-&gt;Modules.count;
	<span class="enscript-keyword">return</span> (Module)(modHdr-&gt;Modules.data);
    }
    <span class="enscript-keyword">else</span> {
	*<span class="enscript-type">size</span> = 0;
	<span class="enscript-keyword">return</span> (Module)0;
    }
}

ProtocolTemplate **_getObjcProtocols(headerType *head, int *nprotos)
{
    objcModHeader *modHdr = _getObjcModHeader(head);

    <span class="enscript-keyword">if</span> (modHdr) {
	*nprotos = modHdr-&gt;Protocols.count;
	<span class="enscript-keyword">return</span> (ProtocolTemplate **)modHdr-&gt;Protocols.data;
    }
    <span class="enscript-keyword">else</span> {
	*nprotos = 0;
	<span class="enscript-keyword">return</span> (ProtocolTemplate **)0;
    }
}


NXConstantStringTemplate **_getObjcStringObjects(headerType *head, int *nstrs)
{
    objcModHeader *modHdr = _getObjcModHeader(head);

    <span class="enscript-keyword">if</span> (modHdr) {
	*nstrs = modHdr-&gt;StringObjects.count;
	<span class="enscript-keyword">return</span> (NXConstantStringTemplate **)modHdr-&gt;StringObjects.data;
    }
    <span class="enscript-keyword">else</span> {
	*nstrs = 0;
	<span class="enscript-keyword">return</span> (NXConstantStringTemplate **)0;
    }
}

Class *_getObjcClassRefs(headerType *head, int *nclasses)
{
    objcModHeader *modHdr = _getObjcModHeader(head);

    <span class="enscript-keyword">if</span> (modHdr) {
	*nclasses = modHdr-&gt;Classes.count;
	<span class="enscript-keyword">return</span> (Class *)modHdr-&gt;Classes.data;
    }
    <span class="enscript-keyword">else</span> {
	*nclasses = 0;
	<span class="enscript-keyword">return</span> (Class *)0;
    }
}

/* returns start of <span class="enscript-type">all</span> objective-c info <span class="enscript-type">and</span> the <span class="enscript-type">size</span> of the data */
void *_getObjcHeaderData(headerType *head, unsigned *<span class="enscript-type">size</span>)
{
  *<span class="enscript-type">size</span> = 0;
  <span class="enscript-keyword">return</span> NULL;
}

SEL *_getObjcMessageRefs(headerType *head, int *nmess)
{
  *nmess = 0;
  <span class="enscript-keyword">return</span> (SEL *)NULL;
}

const <span class="enscript-type">char</span> *_getObjcHeaderName(headerType *header)
{
  <span class="enscript-keyword">return</span> &quot;InvalidHeaderName&quot;;
}
#endif
</pre>
<hr />
</body></html>