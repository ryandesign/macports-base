#!/bin/sh

# This is how we run configure when building the MacPorts installer packages.
# If you don't want a custom build, this is probably how you should run it too.
#
# If you want to use a different prefix, or any other additional configure
# arguments, you can supply them as arguments when invoking this script.
#
# Some environment variables are also supported for altering the defaults:
#
# ARCHFLAGS
#   -arch flags with which to build. If not specified, it is contructed from
#   ARCHS. See also UNIVERSAL.
#
# ARCHS
#   The list of architectures for which to build. If you prefer, specify the
#   -arch flags in ARCHFLAGS instead. See also UNIVERSAL. To disable the use of
#   -arch flags, use "ARCHS=".
#
# CC
#   The C compiler executable.
#
# CFLAGS
#   Additional C compiler flags which are appended to the defaults.
#
# CONFIGURE
#   The path to the configure script. This is needed for out-of-source builds,
#   but MacPorts cannot currently be built out-of-source. See
#   https://trac.macports.org/ticket/28001.
#
# LDFLAGS
#   Additional linker flags which are appended to the defaults.
#
# MACOSX_DEPLOYMENT_TARGET
#   The minimum macOS version on which the built software can run. It has not
#   been tested whether all aspects of MacPorts will function correctly on
#   earlier macOS versions if built on a later macOS version, so changing the
#   value of this variable is not recommended except to perform such testing.
#
# OPTFLAGS
#   Compiler optimization flags.
#
# SDKPATH
#   The path to the macOS SDK with which to build.
#
# UNIVERSAL
#   Whether the default ARCHS are universal (yes/no).

: "${CONFIGURE=./configure}"

PATH=/usr/bin:/bin:/usr/sbin:/sbin

SYSTEM_NAME=$(uname -s)
if [ "$SYSTEM_NAME" = "Darwin" ]; then
    MACOS_VERSION=$(sw_vers -productVersion)
    : "${MACOSX_DEPLOYMENT_TARGET=${MACOS_VERSION%.*}}"
    case ${MACOS_VERSION%.*} in
        10.4)
            : "${CC=/usr/bin/gcc-4.0}"
            : "${SDKPATH=/Developer/SDKs/MacOSX10.4u.sdk}"
            ;;
        10.5)
            : "${CC=/usr/bin/gcc-4.2}"
            ;;
        *)
            : "${CC=/usr/bin/clang}"
            ;;
    esac
    case ${MACOS_VERSION%.*} in
        10.[456])
            : "${UNIVERSAL=yes}"
            ;;
        *)
            : "${UNIVERSAL=no}"
            ;;
    esac
    case ${MACOS_VERSION%.*} in
        10.[45])
            if [ "$UNIVERSAL" = "yes" ]; then
                : "${ARCHS=ppc i386}"
            else
                if [ "$(uname -m)" = "Power Macintosh" ]; then
                    : "${ARCHS=ppc}"
                else
                    : "${ARCHS=i386}"
                fi
            fi
            ;;
        *)
            if [ "$UNIVERSAL" = "yes" ]; then
                : "${ARCHS=x86_64 i386}"
            else
                if [ "$(sysctl -n hw.cpu64bit_capable)" = "1" ]; then
                    : "${ARCHS=x86_64}"
                else
                    : "${ARCHS=i386}"
                fi
            fi
            ;;
    esac
fi

: "${ARCHS=}"
: "${ARCHFLAGS=}"
if [ -z "$ARCHFLAGS" ]; then
    for A in $ARCHS; do
        ARCHFLAGS="$ARCHFLAGS -arch $A"
    done
fi

: "${SDKPATH=}"
if [ -z "$SDKPATH" ]; then
    SDK_CFLAGS=
    SDK_LDFLAGS=
else
    SDK_CFLAGS="-isysroot $SDKPATH"
    SDK_LDFLAGS="-Wl,-syslibroot,$SDKPATH"
fi

: "${MACOSX_DEPLOYMENT_TARGET=}"
: "${CC=cc}"
: "${OPTFLAGS=-Os}"

EXTRA_CFLAGS="${CFLAGS-}"
EXTRA_LDFLAGS="${LDFLAGS-}"

CFLAGS="-pipe $OPTFLAGS $ARCHFLAGS $SDK_CFLAGS $EXTRA_CFLAGS"
LDFLAGS="-Wl,-headerpad_max_install_names $ARCHFLAGS $SDK_LDFLAGS $EXTRA_LDFLAGS"

echo "Running $CONFIGURE with the following environment:"
for VAR in CC CFLAGS LDFLAGS MACOSX_DEPLOYMENT_TARGET PATH; do
    echo "$VAR=\"${!VAR}\""
done

env -i \
    CC="$CC" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    MACOSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
    PATH="$PATH" \
    "$CONFIGURE" \
    --enable-readline \
    "$@"
