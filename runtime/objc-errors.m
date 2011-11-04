<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-errors.m</title>
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
<h1 style="margin:8px;" id="f1">objc-errors.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
/*
 *	objc-errors.m
 * 	Copyright 1988-1996, NeXT Software, Inc.
 */

/*
	NXLogObjcError was snarfed from &quot;logErrorInc.c&quot; in the kit.
  
	Contains code <span class="enscript-keyword">for</span> writing <span class="enscript-keyword">error</span> messages to stderr <span class="enscript-type">or</span> syslog.
  
	This code is included in errors.m in the kit, <span class="enscript-type">and</span> in pbs.c
	so pbs can use it also.
*/

#<span class="enscript-keyword">if</span> defined(WIN32)
    #import &lt;winnt-pdo.h&gt;
    #import &lt;windows.h&gt;
    #import &lt;sys/types.h&gt;
    #import &lt;sys/stat.h&gt;
    #import &lt;io.h&gt;
    #define syslog(a, b, c) 	<span class="enscript-type">fprintf</span>(stderr, b, c)
#<span class="enscript-keyword">else</span> 
    #import &lt;syslog.h&gt;
#endif

    #<span class="enscript-keyword">if</span> defined(NeXT_PDO)
        #<span class="enscript-keyword">if</span> !defined(WIN32)
            #include	&lt;syslog.h&gt;	// major head banging in attempt to <span class="enscript-type">find</span> syslog
            #import 	&lt;stdarg.h&gt;
            #include 	&lt;unistd.h&gt;	// <span class="enscript-keyword">close</span>
        #endif
        #import 	&lt;fcntl.h&gt;	// file open flags
    #endif

#import &quot;objc-private.h&quot;

/*	
 *	this routine handles errors that involve an object (<span class="enscript-type">or</span> <span class="enscript-type">class</span>).
 */
volatile void __objc_error(id rcv, const <span class="enscript-type">char</span> *fmt, <span class="enscript-keyword">...</span>) 
{ 
	va_list vp; 

	va_start(vp,fmt); 
	(*_error)(rcv, fmt, vp); 
	va_end(vp);
	_objc_error (rcv, fmt, vp);	/* In <span class="enscript-type">case</span> (*_error)() returns. */
}

/*
 * 	this routine is never called directly<span class="enscript-keyword">...</span>it is only called indirectly
 * 	through &quot;_error&quot;, <span class="enscript-type">which</span> can be overriden by an application. It is
 *	<span class="enscript-type">not</span> declared static because it needs to be referenced in 
 *	&quot;objc-globaldata.m&quot; (this file organization simplifies the shlib
 *	maintenance problem<span class="enscript-keyword">...</span>oh well). It is, however, a &quot;private extern&quot;.
 */
volatile void _objc_error(id self, const <span class="enscript-type">char</span> *fmt, va_list ap) 
{ 
    <span class="enscript-type">char</span> bigBuffer<span class="enscript-type">[</span>4*1024<span class="enscript-type">]</span>;

    vsprintf (bigBuffer, fmt, ap);
    _NXLogError (&quot;objc: <span class="enscript-comment">%s: %s&quot;, object_getClassName (self), bigBuffer);
</span>
#<span class="enscript-keyword">if</span> defined(WIN32)
    RaiseException(0xdead, EXCEPTION_NONCONTINUABLE, 0, NULL);
#<span class="enscript-keyword">else</span>
    abort();		/* generates a core file */
#endif
}

/*	
 *	this routine handles severe runtime errors<span class="enscript-keyword">...</span>like <span class="enscript-type">not</span> being able
 * 	to read the mach headers, allocate space, etc<span class="enscript-keyword">...</span>very uncommon.
 */
volatile void _objc_fatal(const <span class="enscript-type">char</span> *msg)
{
    _NXLogError(&quot;objc: <span class="enscript-comment">%s\n&quot;, msg);
</span>#<span class="enscript-keyword">if</span> defined(WIN32)
    RaiseException(0xdead, EXCEPTION_NONCONTINUABLE, 0, NULL);
#<span class="enscript-keyword">else</span>
    exit(1);
#endif
}

/*
 *	this routine handles soft runtime errors<span class="enscript-keyword">...</span>like <span class="enscript-type">not</span> being able
 *      add a category to a <span class="enscript-type">class</span> (because it wasn<span class="enscript-keyword">'</span>t linked in).
 */
void _objc_inform(const <span class="enscript-type">char</span> *fmt, <span class="enscript-keyword">...</span>)
{
    va_list ap; 
    <span class="enscript-type">char</span> bigBuffer<span class="enscript-type">[</span>4*1024<span class="enscript-type">]</span>;

    va_start (ap,fmt); 
    vsprintf (bigBuffer, fmt, ap);
    _NXLogError (&quot;objc: <span class="enscript-comment">%s&quot;, bigBuffer);
</span>    va_end (ap);
}

</pre>
<hr />
</body></html>