/// The budget `cost_stays_linear_test` holds parsing, highlighting and search
/// to, in one place because the README quotes it.
///
/// It was written into the assertions as a bare `8` and into the front page as
/// the word "six" — the limit had been raised from six to eight after a CI run
/// came in at 6.05, and the sentence a reader judges the project by stayed
/// where it was. A promise about performance that is stricter than the test
/// enforcing it is the kind of thing a contributor finds out by trusting it.
///
/// `readme_counts_test` holds the front page to these.
library;

/// How many times the work may grow when the document grows [costSpan] times.
///
/// Loose on purpose, and the headroom was bought three times: five failed on
/// an idle machine within a handful of runs, and six passed here five times in
/// a row and then failed on CI at 6.05. A performance test that goes red on
/// its own is worse than none — it teaches everyone to keep going when it does.
const costGrowthLimit = 8;

/// How much bigger the larger document is.
///
/// Four rather than two: at 2× a quadratic step has to be most of the run
/// before the ratio crosses the limit, while at 4× the quadratic part grows
/// sixteenfold against the rest's four.
const costSpan = 4;
