
# set the include path found by configure
INCLUDES= $(all_includes)

# the library search path.
noinst_PROGRAMS = AnalyzeM24 LookupTests PrintPermutations TestM24 lookup
AnalyzeM24_SOURCES = AnalyzeM24.cpp M24PermTable.cpp M24PermTable.h m24.cc \
	m24.h permutation point.cc point.h rand_utils.c rand_utils.h view.cc view.h
PrintPermutations_SOURCES = M24PermTable.cpp M24PermTable.h PrintPerms.cpp \
	m24.cc m24.h point.cc point.h view.cc view.h
LookupTests_SOURCES = M24PermTable.cpp M24PermTable.h lookup_tests.cc m24.cc \
	m24.h point.cc point.h rand_utils.c rand_utils.h view.cc view.h
lookup_SOURCES = Constants.h M24Constants.h M24PermTable.cpp M24PermTable.h \
	lookup.cc m24.cc m24.h mathieu.h permutation point.cc point.h view.cc view.h
bin_PROGRAMS = Lower48
TestM24_SOURCES = M24Tests.cpp m24.cc m24.h permutation point.cc point.h \
	rand_utils.c rand_utils.h view.cc view.h
Lower48_SOURCES = Lower48.cpp M24PermTable.cpp M24PermTable.h Utilities.h m.h \
	m24.cc m24.h point.cc point.h view.cc view.h
