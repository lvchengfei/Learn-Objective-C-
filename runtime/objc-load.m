<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>objc-load.m</title>
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
<h1 style="margin:8px;" id="f1">objc-load.m&nbsp;&nbsp;&nbsp;<span style="font-weight: normal; font-size: 0.5em;">[<a href="?txt">plain text</a>]</span></h1>
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
 *	objc-<span class="enscript-type">load</span>.m
 *	Copyright 1988-1996, NeXT Software, Inc.
 *	Author:	s. naroff
 *
 */

#import &quot;objc-private.h&quot;
#import &lt;objc/objc-runtime.h&gt;
#import &lt;objc/hashtable2.h&gt;
#import &lt;objc/Object.h&gt;
#import &lt;objc/Protocol.h&gt;

#<span class="enscript-keyword">if</span> defined(__MACH__) || defined(WIN32)	
#import &lt;streams/streams.h&gt;
#endif 


#<span class="enscript-keyword">if</span> !defined(NeXT_PDO)
    // MACH
    #include &lt;mach-o/dyld.h&gt;
#endif 

#<span class="enscript-keyword">if</span> defined(WIN32)
    #import &lt;winnt-pdo.h&gt;
    #import &lt;windows.h&gt;
#endif

#<span class="enscript-keyword">if</span> defined(__svr4__)
    #import &lt;dlfcn.h&gt;
#endif

#<span class="enscript-keyword">if</span> defined(__hpux__) || defined(hpux)
    #import &quot;objc_hpux_register_shlib.c&quot;
#endif

extern <span class="enscript-type">char</span> *	getsectdatafromheader	(const headerType * mhp, const <span class="enscript-type">char</span> * segname, const <span class="enscript-type">char</span> * sectname,  int * <span class="enscript-type">size</span>);

/* Private extern */
OBJC_EXPORT void (*callbackFunction)( Class, const <span class="enscript-type">char</span> * );


struct objc_method_list **get_base_method_list(Class cls) {
    struct objc_method_list **ptr = ((struct objc_class * )cls)-&gt;methodLists;
    <span class="enscript-keyword">if</span> (!*ptr) <span class="enscript-keyword">return</span> NULL;
    <span class="enscript-keyword">while</span> ( *ptr != 0 &amp;&amp; *ptr != END_OF_METHODS_LIST ) { ptr++; }
    --ptr;
    <span class="enscript-keyword">return</span> ptr;
}


#<span class="enscript-keyword">if</span> defined(NeXT_PDO) // GENERIC_OBJ_FILE
    void send_load_message_to_class(Class cls, void *header_addr)
    {
    	struct objc_method_list **mlistp = get_base_method_list(cls-&gt;<span class="enscript-type">isa</span>);
    	struct objc_method_list *mlist = mlistp ? *mlistp : NULL;
    	IMP load_method;

	<span class="enscript-keyword">if</span> (mlist) {
		load_method = 
		   class_lookupNamedMethodInMethodList(mlist, &quot;finishLoading:&quot;);

		/* go directly there, we do <span class="enscript-type">not</span> want to accidentally send
	           the finishLoading: message to one of its categories<span class="enscript-keyword">...</span>
	 	*/
		<span class="enscript-keyword">if</span> (load_method)
			(*load_method)((id)cls, @selector(finishLoading:), 
				header_addr);
	}
    }

    void send_load_message_to_category(Category <span class="enscript-type">cat</span>, void *header_addr)
    {
	struct objc_method_list *mlist = <span class="enscript-type">cat</span>-&gt;class_methods;
	IMP load_method;
	Class cls;

	<span class="enscript-keyword">if</span> (mlist) {
		load_method = 
		   class_lookupNamedMethodInMethodList(mlist, &quot;finishLoading:&quot;);

		cls = objc_getClass (<span class="enscript-type">cat</span>-&gt;class_name);

		/* go directly there, we do <span class="enscript-type">not</span> want to accidentally send
	           the finishLoading: message to one of its categories<span class="enscript-keyword">...</span>
	 	*/
		<span class="enscript-keyword">if</span> (load_method)
			(*load_method)(cls, @selector(finishLoading:), 
				header_addr);
	}
    }
#endif // GENERIC_OBJ_FILE

/**********************************************************************************
 * objc_loadModule.
 *
 * NOTE: Loading isn<span class="enscript-keyword">'</span>t really thread safe.  If a <span class="enscript-type">load</span> message recursively calls
 * objc_loadModules() both sets will be loaded correctly, but <span class="enscript-keyword">if</span> the original
 * caller calls objc_unloadModules() it will probably unload the wrong modules.
 * If a <span class="enscript-type">load</span> message calls objc_unloadModules(), then it will unload
 * the modules currently being loaded, <span class="enscript-type">which</span> will probably cause a crash.
 *
 * Error handling is still somewhat crude.  If we encounter errors <span class="enscript-keyword">while</span>
 * linking up classes <span class="enscript-type">or</span> categories, we will <span class="enscript-type">not</span> recover correctly.
 *
 * I removed attempts to lock the <span class="enscript-type">class</span> hashtable, since this introduced
 * deadlock <span class="enscript-type">which</span> was hard to remove.  The only way you can <span class="enscript-type">get</span> into trouble
 * is <span class="enscript-keyword">if</span> one thread loads a module <span class="enscript-keyword">while</span> another thread tries to access the
 * loaded classes (using objc_lookUpClass) before the <span class="enscript-type">load</span> is complete.
 **********************************************************************************/
int		objc_loadModule	   (const <span class="enscript-type">char</span> *			moduleName, 
							void			(*class_callback) (Class, const <span class="enscript-type">char</span> *categoryName),
							int *			errorCode)
{
	int								successFlag = 1;
	int								locErrorCode;
#<span class="enscript-keyword">if</span> defined(__MACH__)	
	NSObjectFileImage				objectFileImage;
	NSObjectFileImageReturnCode		code;
#endif
#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__) || defined(__hpux__) || defined(hpux)
	void *		handle;
	void		(*save_class_callback) (Class, const <span class="enscript-type">char</span> *) = load_class_callback;
#endif

	// So we don<span class="enscript-keyword">'</span>t have to check this everywhere
	<span class="enscript-keyword">if</span> (errorCode == NULL)
		errorCode = &amp;locErrorCode;

#<span class="enscript-keyword">if</span> defined(__MACH__)
	<span class="enscript-keyword">if</span> (moduleName == NULL)
	{
		*errorCode = NSObjectFileImageInappropriateFile;
		<span class="enscript-keyword">return</span> 0;
	}

	<span class="enscript-keyword">if</span> (_dyld_present () == 0)
	{
		*errorCode = NSObjectFileImageFailure;
		<span class="enscript-keyword">return</span> 0;
	}

	callbackFunction = class_callback;
	code = NSCreateObjectFileImageFromFile (moduleName, &amp;objectFileImage);
	<span class="enscript-keyword">if</span> (code != NSObjectFileImageSuccess)
	{
		*errorCode = code;
 		<span class="enscript-keyword">return</span> 0;
	}

#<span class="enscript-keyword">if</span> !defined(__OBJC_DONT_USE_NEW_NSLINK_OPTION__)
	<span class="enscript-keyword">if</span> (NSLinkModule(objectFileImage, moduleName, NSLINKMODULE_OPTION_RETURN_ON_ERROR) == NULL) {
	    NSLinkEditErrors <span class="enscript-keyword">error</span>;
	    int errorNum;
	    <span class="enscript-type">char</span> *fileName, *errorString;
	    NSLinkEditError(&amp;<span class="enscript-keyword">error</span>, &amp;errorNum, &amp;fileName, &amp;errorString);
	    // These errors may overlap with other errors that objc_loadModule returns in other failure cases.
	    *errorCode = <span class="enscript-keyword">error</span>;
	    <span class="enscript-keyword">return</span> 0;
	}
#<span class="enscript-keyword">else</span>
        (void)NSLinkModule(objectFileImage, moduleName, NSLINKMODULE_OPTION_NONE);
#endif
	callbackFunction = NULL;

#<span class="enscript-keyword">else</span>
	// The PDO cases
	<span class="enscript-keyword">if</span> (moduleName == NULL)
	{
		*errorCode = 0;
		<span class="enscript-keyword">return</span> 0;
	}

	OBJC_LOCK(&amp;loadLock);

#<span class="enscript-keyword">if</span> defined(WIN32) || defined(__svr4__) || defined(__hpux__) || defined(hpux)

	load_class_callback = class_callback;

#<span class="enscript-keyword">if</span> defined(WIN32)
	<span class="enscript-keyword">if</span> ((handle = LoadLibrary (moduleName)) == NULL)
	{
		FreeLibrary(moduleName);
		*errorCode = 0;
		successFlag = 0;
	}

#elif defined(__svr4__)
	handle = dlopen(moduleName, (RTLD_NOW | RTLD_GLOBAL));
	<span class="enscript-keyword">if</span> (handle == 0)
	{
		*errorCode = 0;
		successFlag = 0;
	}
	<span class="enscript-keyword">else</span>
	{
		objc_register_header(moduleName);
		objc_finish_header();
	}

#<span class="enscript-keyword">else</span>
        handle = shl_load(moduleName, BIND_IMMEDIATE | BIND_VERBOSE, 0L);
        <span class="enscript-keyword">if</span> (handle == 0)
        {
                *errorCode = 0;
                successFlag = 0;
        }
        <span class="enscript-keyword">else</span>
            ; // Don<span class="enscript-keyword">'</span>t do anything here: the shlib should have been built
              // with the +I<span class="enscript-keyword">'</span>objc_hpux_register_shlib<span class="enscript-keyword">'</span> option
#endif

	load_class_callback = save_class_callback;

#elif defined(NeXT_PDO) 
	// NOTHING YET<span class="enscript-keyword">...</span>
	successFlag = 0;
#endif // WIN32

	OBJC_UNLOCK (&amp;loadLock);

#endif // MACH

	<span class="enscript-keyword">return</span> successFlag;
}

/**********************************************************************************
 * objc_loadModules.
 **********************************************************************************/
    /* Lock <span class="enscript-keyword">for</span> dynamic loading <span class="enscript-type">and</span> unloading. */
	static OBJC_DECLARE_LOCK (loadLock);
#<span class="enscript-keyword">if</span> defined(NeXT_PDO) // GENERIC_OBJ_FILE
	void		(*load_class_callback) (Class, const <span class="enscript-type">char</span> *);
#endif 


long	objc_loadModules   (<span class="enscript-type">char</span> *			modlist<span class="enscript-type">[</span><span class="enscript-type">]</span>, 
							void *			errStream,
							void			(*class_callback) (Class, const <span class="enscript-type">char</span> *),
							headerType **	hdr_addr,
							<span class="enscript-type">char</span> *			debug_file)
{
	<span class="enscript-type">char</span> **				modules;
	int					code;
	int					itWorked;

	<span class="enscript-keyword">if</span> (modlist == 0)
		<span class="enscript-keyword">return</span> 0;

	<span class="enscript-keyword">for</span> (modules = &amp;modlist<span class="enscript-type">[</span>0<span class="enscript-type">]</span>; *modules != 0; modules++)
	{
		itWorked = objc_loadModule (*modules, class_callback, &amp;code);
		<span class="enscript-keyword">if</span> (itWorked == 0)
		{
#<span class="enscript-keyword">if</span> defined(__MACH__) || defined(WIN32)	
			<span class="enscript-keyword">if</span> (errStream)
				NXPrintf ((NXStream *) errStream, &quot;objc_loadModules(<span class="enscript-comment">%s) code = %d\n&quot;, *modules, code);
</span>#endif
			<span class="enscript-keyword">return</span> 1;
		}

		<span class="enscript-keyword">if</span> (hdr_addr)
			*(hdr_addr++) = 0;
	}

	<span class="enscript-keyword">return</span> 0;
}

/**********************************************************************************
 * objc_unloadModules.
 *
 * NOTE:  Unloading isn<span class="enscript-keyword">'</span>t really thread safe.  If an unload message calls
 * objc_loadModules() <span class="enscript-type">or</span> objc_unloadModules(), then the current call
 * to objc_unloadModules() will probably unload the wrong stuff.
 **********************************************************************************/

long	objc_unloadModules (void *			errStream,
							void			(*unload_callback) (Class, Category))
{
	headerType *	header_addr = 0;
	int errflag = 0;

        // TODO: to make unloading work, should <span class="enscript-type">get</span> the current header

	<span class="enscript-keyword">if</span> (header_addr)
	{
                ; // TODO: unload the current header
	}
	<span class="enscript-keyword">else</span>
	{
		errflag = 1;
	}

  <span class="enscript-keyword">return</span> errflag;
}

</pre>
<hr />
</body></html>