#
#   Critcl - build C extensions on-the-fly
#
#   Copyright (c) 2001-2006 Jean-Claude Wippler
#   Copyright (c) 2002-2007 Steve Landers
#
#   See http://www.purl.org/tcl/wiki/critcl
#
#   This is the Critcl runtime that loads the appropriate
#   shared library when a package is requested
#

namespace eval ::critcl2 {

    proc loadlib {dir package version mapping args} {
        global tcl_platform
        set path [file join $dir [::critcl::platform $mapping]]
        set ext [info sharedlibextension]
        set lib [file join $path $package$ext]
        set provide [list]
	if {[llength $args]} {
            set preload [file join $path preload$ext]
	    foreach p $args {
		set prelib [file join $path $p$ext]
		if {[file readable $preload] && [file readable $prelib]} {
		    lappend provide [list load $preload]
                    lappend provide [list @preload $prelib]
                }
            }
        }
        # we have a fallback to pure-Tcl if no platform-specific version
        # is present: in this case we don't build on the fly.
        if {[file exists $lib]} {
            lappend provide [list load $lib $package]
        }
        foreach t [glob -nocomplain [file join $dir Tcl *.tcl]] {
            lappend provide [list source $t]
        }
        lappend provide "package provide $package $version"
        package ifneeded $package $version [join $provide "; "]
        package ifneeded critcl 0.0 \
         "package provide critcl 0.0; [list source [file join $dir critcl.tcl]]"
    }
}

namespace eval ::critcl {
    # a version of critcl::platform that applies the platform mapping
    proc platform {{mapping ""}} {
        set platform [::platform::generic]
        set version $::tcl_platform(osVersion)
        if {[string match "macosx-*" $platform]} {
            # "normalize" the osVersion to match OSX release numbers
            set v [split $version .]
            set v1 [lindex $v 0]
            set v2 [lindex $v 1]
            incr v1 -4
            set version 10.$v1.$v2
        }
        foreach {config map} $mapping {
            if {[string match $config $platform]} {
                set minver [lindex $map 1]
                if {[package vcompare $version $minver] != -1} {
                    set platform [lindex $map 0]
                    break
                }
            }
        }
        return $platform
    }
}

# dummy Critcl procs
namespace eval ::critcl {
  proc cache args {}
  proc ccode args {}
  proc ccommand args {}
  proc cdata args {}
  proc cdefines args {}
  proc cflags args {}
  proc cheaders args {}
  proc check args {return 0}
  proc cinit args {}
  proc clibraries args {}
  proc compiled args {return 1}
  proc compiling args {return 0}
  proc config args {}
  proc cproc args {}
  proc csources args {}
  proc debug args {}
  proc done args {return 1}
  proc failed args {}
  proc framework args {}
  proc ldflags args {}
  proc tk args {}
  proc tsources args {}
  proc preload args {}
  proc license args {}
}

# a clone of platform::generic
namespace eval ::platform {
    proc generic {} {
    global tcl_platform

    set plat [string tolower [lindex $tcl_platform(os) 0]]
    set cpu  $tcl_platform(machine)

    switch -glob -- $cpu {
	sun4* {
	    set cpu sparc
	}
	intel -
	i*86* {
	    set cpu ix86
	}
	x86_64 {
	    if {$tcl_platform(wordSize) == 4} {
		# See Example <1> at the top of this file.
		set cpu ix86
	    }
	}
	"Power*" {
	    set cpu powerpc
	}
	"arm*" {
	    set cpu arm
	}
	ia64 {
	    if {$tcl_platform(wordSize) == 4} {
		append cpu _32
	    }
	}
    }

    switch -- $plat {
	windows {
	    set plat win32
	    if {$cpu eq "amd64"} {
		# Do not check wordSize, win32-x64 is an IL32P64 platform.
		set cpu x86_64
	    }
	}
	sunos {
	    set plat solaris
	    if {$cpu ne "ia64"} {
		if {$tcl_platform(wordSize) == 8} {
		    append cpu 64
		}
	    }
	}
	darwin {
	    set plat macosx
	}
	aix {
	    set cpu powerpc
	    if {$tcl_platform(wordSize) == 8} {
		append cpu 64
	    }
	}
	hp-ux {
	    set plat hpux
	    if {$cpu ne "ia64"} {
		set cpu parisc
		if {$tcl_platform(wordSize) == 8} {
		    append cpu 64
		}
	    }
	}
	osf1 {
	    set plat tru64
	}
    }

    return "${plat}-${cpu}"

    }
}


