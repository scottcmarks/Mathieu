
# set the include path found by configure
INCLUDES= $(all_includes)

# the library search path.
noinst_PROGRAMS = AnalyzeM12 LookupTests PrintPermutations TestM12 lookup
AnalyzeM12_SOURCES = AnalyzeM12.cpp M12PermTable.cpp M12PermTable.h Utilities.h \
	m.h m12.cc m12.h mathieu.h permutation point.cc point.h rand_utils.c \
	rand_utils.h view.cc view.h
PrintPermutations_SOURCES = M12PermTable.cpp M12PermTable.h PrintPerms.cpp \
	m12.cc m12.h mathieu.h point.cc point.h view.cc view.h
LookupTests_SOURCES = M12PermTable.cpp M12PermTable.h lookup_tests.cc m12.cc \
	m12.h mathieu.h point.cc point.h rand_utils.c rand_utils.h view.cc view.h
lookup_SOURCES = M12PermTable.cpp M12PermTable.h ParsePermutations.cpp \
	ParsePermutations.h lookup.cc m12.cc m12.h mathieu.h permutation point.cc point.h split \
	view.cc view.h
TestM12_SOURCES = M12Tests.cpp m12.cc m12.h mathieu.h permutation point.cc \
	point.h rand_utils.c rand_utils.h view.cc view.h
