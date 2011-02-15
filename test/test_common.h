
#include <usual/base.h>

#include "tinytest.h"
#include "tinytest_macros.h"

#define str_check(a, b) tt_str_op(a, ==, b)
#define int_check(a, b) tt_int_op(a, ==, b)
#define ull_check(a, b) tt_assert_op_type(a, ==, b, uint64_t, "%" PRIu64)

extern struct testcase_t aatree_tests[];
extern struct testcase_t cbtree_tests[];
extern struct testcase_t string_tests[];
extern struct testcase_t crypto_tests[];
extern struct testcase_t heap_tests[];
extern struct testcase_t list_tests[];
extern struct testcase_t utf8_tests[];
extern struct testcase_t strpool_tests[];
extern struct testcase_t pgutil_tests[];
extern struct testcase_t regex_tests[];
extern struct testcase_t cxalloc_tests[];
extern struct testcase_t bits_tests[];
extern struct testcase_t base_tests[];
extern struct testcase_t netdb_tests[];
extern struct testcase_t cfparser_tests[];
extern struct testcase_t endian_tests[];
extern struct testcase_t hashtab_tests[];
extern struct testcase_t mdict_tests[];
extern struct testcase_t shlist_tests[];
extern struct testcase_t time_tests[];
extern struct testcase_t hashing_tests[];
extern struct testcase_t fileutil_tests[];
extern struct testcase_t socket_tests[];

