
dnl Those depend on correct order:
dnl  AC_USUAL_INIT
dnl  AC_USUAL_PROGRAM_CHECK
dnl  AC_USUAL_HEADER_CHECK
dnl  AC_USUAL_TYPE_CHECK
dnl  AC_USUAL_FUNCTION_CHECK
dnl Order does not matter:
dnl  AC_USUAL_CASSERT
dnl  AC_USUAL_WERROR
dnl  AC_USUAL_DEBUG
dnl Optional features:
dnl  AC_USUAL_LIBEVENT / AC_USUAL_LIBEVENT_OPT
dnl  AC_USUAL_UREGEX
dnl  AC_USUAL_GETADDRINFO_A
dnl  AC_USUAL_TLS

dnl
dnl  AC_USUAL_INIT:
dnl    - Sets PORTNAME=win32/unix
dnl    - If building from separate dir, writes top-level Makefile (antimake)
dnl
dnl  Also defines port-specific flags:
dnl   _GNU_SOURCE, _WIN32_WINNT, WIN32_LEAN_AND_MEAN
dnl
AC_DEFUN([AC_USUAL_INIT], [

# if building separately from srcdir, write top-level makefile
if test "$srcdir" != "."; then
  echo "include $srcdir/Makefile" > Makefile
fi

AC_MSG_CHECKING([target host type])
xhost="$host_alias"
if test "x$xhost" = "x"; then
  xhost=`uname -s`
fi
case "$xhost" in
*cygwin* | *mingw* | *pw32* | *MINGW*)
   LIBS="$LIBS -lws2_32"
   PORTNAME=win32;;
*) PORTNAME=unix ;;
esac
AC_SUBST(PORTNAME)
AC_MSG_RESULT([$PORTNAME])
dnl Set the flags before any feature tests.
if test "$PORTNAME" = "win32"; then
  AC_DEFINE([WIN32_LEAN_AND_MEAN], [1], [Define to request cleaner win32 headers.])
  AC_DEFINE([WINVER], [0x0600], [Define to max win32 API version (0x0600=Vista).])
else
  AC_DEFINE([_GNU_SOURCE], [1], [Define to get working glibc.])
fi

dnl Package-specific data
AC_SUBST([pkgdatadir], ['${datarootdir}'/${PACKAGE_TARNAME}])
dnl pkgconfig files
AC_SUBST([pkgconfigdir], ['${libdir}/pkgconfig'])

])

dnl Old name for initial checks
AC_DEFUN([AC_USUAL_PORT_CHECK], [AC_USUAL_INIT])

dnl
dnl AC_USUAL_PROGRAM_CHECK:  Simple C environment: CC, CPP, INSTALL
dnl
AC_DEFUN([AC_USUAL_PROGRAM_CHECK], [
AC_PROG_CC_STDC
AC_PROG_CPP
dnl Check if compiler supports __func__
AC_CACHE_CHECK([whether compiler supports __func__], pgac_cv_funcname_func,
  [AC_TRY_COMPILE([#include <stdio.h>], [printf("%s\n", __func__);],
    [pgac_cv_funcname_func=yes], [pgac_cv_funcname_func=no])])
if test x"$pgac_cv_funcname_func" = xyes ; then
  AC_DEFINE(HAVE_FUNCNAME__FUNC, 1,
    [Define to 1 if your compiler understands __func__.])
fi
dnl Check if linker supports -Wl,--as-needed
if test "$GCC" = "yes"; then
  old_LDFLAGS="$LDFLAGS"
  LDFLAGS="$LDFLAGS -Wl,--as-needed"
  AC_MSG_CHECKING([whether linker supports --as-needed])
  AC_LINK_IFELSE([AC_LANG_SOURCE([int main(void) { return 0; }])],
    [AC_MSG_RESULT([yes])],
    [AC_MSG_RESULT([no])
     LDFLAGS="$old_LDFLAGS"])
fi

dnl Check if compiler supports gcc-style dependencies
AC_MSG_CHECKING([whether compiler supports dependency generation])
old_CFLAGS="$CFLAGS"
CFLAGS="$CFLAGS -MD -MP -MT conftest.o -MF conftest.o.d"
AC_COMPILE_IFELSE([AC_LANG_SOURCE([void foo(void){}])],
     [HAVE_CC_DEPFLAG=yes], [HAVE_CC_DEPFLAG=no])
rm -f conftest.d
CFLAGS="$old_CFLAGS"
AC_MSG_RESULT([$HAVE_CC_DEPFLAG])
AC_SUBST(HAVE_CC_DEPFLAG)

dnl Pick good warning flags for gcc
WFLAGS=""
if test x"$GCC" = xyes; then
  AC_MSG_CHECKING([for working warning switches])
  good_CFLAGS="$CFLAGS"
  flags="-Wall -Wextra"
  # turn off noise from Wextra
  flags="$flags -Wno-unused-parameter -Wno-missing-field-initializers"
  # Wextra does not turn those on?
  flags="$flags -Wmissing-prototypes -Wpointer-arith -Wendif-labels"
  flags="$flags -Wdeclaration-after-statement -Wold-style-definition"
  flags="$flags -Wstrict-prototypes -Wundef -Wformat=2"
  flags="$flags -Wuninitialized"
  for f in $flags; do
    CFLAGS="$good_CFLAGS $WFLAGS $f"
    AC_COMPILE_IFELSE([AC_LANG_SOURCE([void foo(void){}])],
	[WFLAGS="$WFLAGS $f"])
  done

  # avoid -Wextra if missing-field.initializers does not work
  echo "$WFLAGS" | grep missing-field-initializers > /dev/null \
  || WFLAGS=`echo "$WFLAGS"|sed 's/ -Wextra//'`

  CFLAGS="$good_CFLAGS"
  AC_MSG_RESULT([done])
fi
AC_SUBST(WFLAGS)

AC_PROG_INSTALL

AC_PROG_LN_S
AC_PROG_EGREP
AC_PROG_AWK

dnl AC_PROG_MKDIR_P and AC_PROG_SED are from newer autotools
m4_ifdef([AC_PROG_MKDIR_P], [
  AC_PROG_MKDIR_P
], [
  MKDIR_P="mkdir -p"
  AC_SUBST(MKDIR_P)
])
m4_ifdef([AC_PROG_SED], [
  AC_PROG_SED
], [
  SED="sed"
  AC_SUBST(SED)
])

dnl Convert relative path to absolute path.
case "$ac_install_sh" in
./*)  ac_install_sh="`pwd`/${ac_install_sh}" ;;
../*) ac_install_sh="`pwd`/${ac_install_sh}" ;;
esac
case "$INSTALL" in
./*)  INSTALL="`pwd`/${INSTALL}" ;;
../*) INSTALL="`pwd`/${INSTALL}" ;;
esac
case "$MKDIR_P" in
./*)  MKDIR_P="`pwd`/${MKDIR_P}" ;;
../*) MKDIR_P="`pwd`/${MKDIR_P}" ;;
esac

AC_CHECK_TOOL([STRIP], [strip])
AC_CHECK_TOOL([RANLIB], [ranlib], [true])
AC_CHECK_TOOL([AR], [ar])
ARFLAGS=rcu
AC_SUBST(ARFLAGS)
])


dnl
dnl AC_USUAL_TYPE_CHECK: Basic types for C
dnl
AC_DEFUN([AC_USUAL_TYPE_CHECK], [
AC_C_INLINE
AC_C_RESTRICT
AC_C_BIGENDIAN
AC_SYS_LARGEFILE
AC_TYPE_PID_T
AC_TYPE_UID_T
AC_TYPE_SIZE_T
]) 

dnl
dnl  AC_USUAL_HEADER_CHECK:  Basic headers
dnl
AC_DEFUN([AC_USUAL_HEADER_CHECK], [
AC_CHECK_HEADERS([inttypes.h stdbool.h unistd.h sys/time.h])
AC_CHECK_HEADERS([sys/socket.h poll.h sys/poll.h sys/un.h])
AC_CHECK_HEADERS([arpa/inet.h netinet/in.h netinet/tcp.h])
AC_CHECK_HEADERS([sys/param.h sys/uio.h pwd.h grp.h])
AC_CHECK_HEADERS([sys/wait.h sys/mman.h syslog.h netdb.h dlfcn.h])
AC_CHECK_HEADERS([err.h pthread.h endian.h sys/endian.h byteswap.h])
AC_CHECK_HEADERS([malloc.h regex.h getopt.h fnmatch.h])
AC_CHECK_HEADERS([langinfo.h xlocale.h linux/random.h])
dnl ucred.h may have prereqs
AC_CHECK_HEADERS([ucred.h sys/ucred.h], [], [], [
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
])
])


dnl
dnl  AC_USUAL_FUNCTION_CHECK:  Basic functions
dnl
AC_DEFUN([AC_USUAL_FUNCTION_CHECK], [
### Functions provided if missing
dnl AC_CHECK_FUNCS(basename dirname) # unstable, provide always
AC_CHECK_FUNCS(strlcpy strlcat strnlen strsep getpeereid sigaction sigqueue)
AC_CHECK_FUNCS(memmem memrchr mempcpy)
AC_CHECK_FUNCS(inet_ntop inet_pton poll getline regcomp)
AC_CHECK_FUNCS(err errx warn warnx getprogname setprogname)
AC_CHECK_FUNCS(posix_memalign memalign valloc explicit_bzero memset_s reallocarray)
AC_CHECK_FUNCS(getopt getopt_long getopt_long_only)
AC_CHECK_FUNCS(fls flsl flsll ffs ffsl ffsll)
AC_CHECK_FUNCS(fnmatch mbsnrtowcs nl_langinfo strtod_l strtonum)
AC_CHECK_FUNCS(asprintf vasprintf timegm)
### Functions provided only on win32
AC_CHECK_FUNCS(localtime_r gettimeofday recvmsg sendmsg usleep getrusage)
### Functions used by libusual itself
AC_CHECK_FUNCS(syslog mmap getpeerucred arc4random_buf getentropy getrandom)
### win32: link with ws2_32
AC_SEARCH_LIBS(WSAGetLastError, ws2_32)
AC_FUNC_STRERROR_R
###
AC_MSG_CHECKING([for integer enc/dec functions])
AC_LINK_IFELSE([AC_LANG_SOURCE([
  #include <sys/types.h>
  #ifdef HAVE_SYS_ENDIAN_H
  #include <sys/endian.h>
  #endif
  #ifdef HAVE_ENDIAN_H
  #include <endian.h>
  #endif
  char p[[]] = "01234567";
  int main(void) {
    be16enc(p, 0); be32enc(p, 1); be64enc(p, 2);
    le16enc(p, 2); le32enc(p, 3); le64enc(p, 4);
    return (int)(be16dec(p) + be32dec(p) + be64dec(p)) +
           (int)(le16dec(p) + le32dec(p) + le64dec(p));
  } ])],
[ AC_MSG_RESULT([found])
  AC_DEFINE([HAVE_ENCDEC_FUNCS], [1], [Define if *enc & *dec functions are available]) ],
[AC_MSG_RESULT([not found])])

])

dnl
dnl  AC_USUAL_CASSERT:  --enable-cassert switch to set macro CASSERT
dnl
AC_DEFUN([AC_USUAL_CASSERT], [
AC_ARG_ENABLE(cassert, AC_HELP_STRING([--enable-cassert],[turn on assert checking in code]))
AC_MSG_CHECKING([whether to enable asserts])
if test "$enable_cassert" = "yes"; then
  AC_DEFINE(CASSERT, 1, [Define to enable assert checking])
  AC_MSG_RESULT([yes])
else
  AC_MSG_RESULT([no])
fi
])


dnl
dnl  AC_USUAL_WERROR:  --enable-werror switch to turn warnings into errors
dnl
AC_DEFUN([AC_USUAL_WERROR], [
AC_ARG_ENABLE(werror, AC_HELP_STRING([--enable-werror],[add -Werror to CFLAGS]))
AC_MSG_CHECKING([whether to fail on warnings])
if test "$enable_werror" = "yes"; then
  CFLAGS="$CFLAGS -Werror"
  AC_MSG_RESULT([yes])
else
  AC_MSG_RESULT([no])
fi
])


dnl
dnl  AC_USUAL_DEBUG:  --disable-debug switch to strip binary
dnl
AC_DEFUN([AC_USUAL_DEBUG], [
AC_ARG_ENABLE(debug,
  AC_HELP_STRING([--disable-debug],[strip binary]),
  [], [enable_debug=yes])
AC_MSG_CHECKING([whether to build debug binary])
if test "$enable_debug" = "yes"; then
  LDFLAGS="-g $LDFLAGS"
  BININSTALL="$INSTALL"
  AC_MSG_RESULT([yes])
else
  BININSTALL="$INSTALL -s"
  AC_MSG_RESULT([no])
fi
AC_SUBST(enable_debug)
])


dnl
dnl  AC_USUAL_LIBEVENT:  --with-libevent
dnl
dnl  AC_USUAL_LIBEVENT - prefer-yes:
dnl     default   - search for libevent, error if not found
dnl     --with    - search for libevent, error if not found
dnl     --without - use libusual
dnl
dnl  AC_USUAL_LIBEVENT_OPT - prefer-no:
dnl     default   - use libusual
dnl     --with    - search for libevent, error if not found
dnl     --without - use libusual
dnl
AC_DEFUN([AC_USUAL_LIBEVENT_OPT], [AC_USUAL_LIBEVENT(1)])
AC_DEFUN([AC_USUAL_LIBEVENT], [
ifelse([$#], [0], [levent=yes], [levent=no])
AC_MSG_CHECKING([for libevent])
AC_ARG_WITH(libevent,
  AC_HELP_STRING([--with-libevent=prefix],[Specify where libevent is installed]),
  [ if test "$withval" = "no"; then
      levent=no
    elif test "$withval" = "yes"; then
      levent=yes
    else
      levent=yes
      CPPFLAGS="$CPPFLAGS -I$withval/include"
      LDFLAGS="$LDFLAGS -L$withval/lib"
    fi
  ], [])

if test "$levent" = "no"; then
  AC_MSG_RESULT([using usual/event])
  AC_DEFINE(HAVE_EVENT_LOOPBREAK, 1, [usual/event.h has it.])
  AC_DEFINE(HAVE_EVENT_BASE_NEW, 1, [usual/event.h has it.])
  have_libevent=no
else # libevent
AC_DEFINE(HAVE_LIBEVENT, 1, [Use real libevent.])
LIBS="-levent $LIBS"
AC_LINK_IFELSE([AC_LANG_SOURCE([
  #include <sys/types.h>
  #include <sys/time.h>
  #include <stdio.h>
  #include <event.h>
  int main(void) {
    struct event ev;
    event_init();
    event_set(&ev, 1, EV_READ, NULL, NULL);
    /* this checks for 1.2+ */
    event_base_free(NULL);
  } ])],
[AC_MSG_RESULT([found])],
[AC_MSG_ERROR([not found, cannot proceed])])

AC_CHECK_FUNCS(event_loopbreak event_base_new evdns_base_new)
have_libevent=yes
fi # libevent
AC_SUBST(have_libevent)

]) dnl  AC_USUAL_LIBEVENT

dnl
dnl  AC_USUAL_UREGEX:  --with-uregex
dnl
dnl    Allow override of system regex
dnl
AC_DEFUN([AC_USUAL_UREGEX], [
AC_MSG_CHECKING([whether to force internal regex])
uregex=no
AC_ARG_WITH(uregex,
  AC_HELP_STRING([--with-uregex],[Force use of internal regex]),
  [ if test "$withval" = "yes"; then
      uregex=yes
    fi ], [])

if test "$uregex" = "yes"; then
  AC_MSG_RESULT([yes])
  AC_DEFINE(USE_INTERNAL_REGEX, 1, [Define to force use of uRegex.])
else
  AC_MSG_RESULT([no])
fi
]) dnl  AC_USUAL_UREGEX

dnl
dnl  AC_USUAL_GETADDRINFO_A - getaddrinfo_a() is required
dnl
AC_DEFUN([AC_USUAL_GETADDRINFO_A], [
AC_SEARCH_LIBS(getaddrinfo_a, anl)
AC_CACHE_CHECK([whether to use native getaddinfo_a], ac_cv_usual_glibc_gaia,
  [AC_TRY_LINK([
#include <stdio.h>
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
], [
#if __GLIBC_PREREQ(2,9)
	getaddrinfo_a(0,NULL,0,NULL);
#else
	none or broken
#endif
], [ac_cv_usual_glibc_gaia=yes], [ac_cv_usual_glibc_gaia=no])])

if test x"$ac_cv_usual_glibc_gaia" = xyes ; then
  AC_DEFINE(HAVE_GETADDRINFO_A, 1, [Define to 1 if you have the getaddrinfo_a() function.])
else
  ACX_PTHREAD(, [AC_MSG_RESULT([Threads not available and fallback getaddrinfo_a() non-functional.])])
  CC="$PTHREAD_CC"
  CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
  LIBS="$LIBS $PTHREAD_LIBS"
fi
])


dnl
dnl  AC_USUAL_TLS:  --with-openssl [ / --with-gnutls ? ]
dnl
dnl  AC_USUAL_TLS           - prefer-yes:
dnl     default             - search for libssl, error if not found
dnl     --with-openssl      - search for libssl, error if not found
dnl     --with-openssl=pfx  - search for libssl, error if not found, use pfx
dnl     --without-openssl   - no tls
dnl
AC_DEFUN([AC_USUAL_TLS],[

dnl values: no, libssl, auto
tls_support=auto

TLS_CPPFLAGS=""
TLS_LDFLAGS=""
TLS_LIBS=""

AC_MSG_CHECKING([for OpenSSL])
AC_ARG_WITH(openssl,
  AC_HELP_STRING([--with-openssl=prefix], [Specify where OpenSSL is installed]),
  [ if test "$withval" = "no"; then
      tls_support=no
    elif test "$withval" = "yes"; then
      tls_support=libssl
      TLS_LIBS="-lssl -lcrypto"
    else
      tls_support=libssl
      TLS_CPPFLAGS="-I$withval/include"
      TLS_LDFLAGS="-L$withval/lib"
      TLS_LIBS="-lssl -lcrypto"
    fi
  ], [
    tls_support=auto
    TLS_CPPFLAGS=""
    TLS_LDFLAGS=""
    TLS_LIBS="-lssl -lcrypto"
  ])

dnl check if libssl works
if test "$tls_support" = "auto" -o "$tls_support" = "libssl"; then
  AC_DEFINE(USUAL_LIBSSL_FOR_TLS, 1, [Use libssl for TLS.])
  tmp_LIBS="$LIBS"
  tmp_LDFLAGS="$LDFLAGS"
  tmp_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$TLS_CPPFLAGS $CPPFLAGS"
  LDFLAGS="$TLS_LDFLAGS $LDFLAGS"
  LIBS="$TLS_LIBS $LIBS"
  AC_LINK_IFELSE([
    AC_LANG_PROGRAM([[#include <openssl/ssl.h>]],
                    [[SSL_CTX *ctx = SSL_CTX_new(TLSv1_2_method());]])],
    [ tls_support=yes; AC_MSG_RESULT([found])],
    [ AC_MSG_ERROR([not found]) ])
  dnl check LibreSSL-only APIs
  AC_CHECK_FUNCS(SSL_CTX_use_certificate_chain_mem SSL_CTX_load_verify_mem asn1_time_parse)
  CPPFLAGS="$tmp_CPPFLAGS"
  LDFLAGS="$tmp_LDFLAGS"
  LIBS="$tmp_LIBS"

  dnl Pick default root CA file
  cafile=auto
  AC_MSG_CHECKING([for root CA certs])
  AC_ARG_WITH(root-ca-file,
    AC_HELP_STRING([--with-root-ca-file=cafile], [Specify where root CA certs are.]),
    [ if test "$withval" = "no"; then
        :
      elif test "$withval" = "yes"; then
        :
      else
        cafile="$withval"
      fi
    ])
  if test "$cafile" = "auto"; then
    for cafile in /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem; do
      if test -f "$cafile"; then
        break
      fi
    done
  fi
  AC_DEFINE_UNQUOTED(USUAL_TLS_CA_FILE, ["$cafile"], [Path to root CA certs.])
  AC_MSG_RESULT([$cafile])
else
  AC_MSG_RESULT([no])
fi

AC_SUBST(tls_support)
AC_SUBST(TLS_CPPFLAGS)
AC_SUBST(TLS_LDFLAGS)
AC_SUBST(TLS_LIBS)

]) dnl  AC_USUAL_TLS


