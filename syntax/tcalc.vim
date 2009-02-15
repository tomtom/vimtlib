" tcalc.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-11-27.
" @Last Change: 2009-02-15.
" @Revision:    0.0.45

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif
if version < 508
    command! -nargs=+ HiLink hi link <args>
else
    command! -nargs=+ HiLink hi def link <args>
endif


syntax keyword TCalcWords
            \ ls yank y define let rm unlet hex HEX oct bin
            \ dec print inspect float format dup d copy c pop p
            \ . del delete rot r swap s stack_empty? stack_size
            \ iqueue_empty? iqueue_size Array group g ungroup u
            \ Sequence seq map mmap plot if ifelse recapture do
            \ clear debug begin end Rational Complex Integer
            \ Matrix at args assert validate source require
            \ history p pp #
            \ % * ** + +@ - -@ / < <= <=> == === =~ > >= DIG E EPSILON I
            \ MANT_DIG MAX MAX_10_EXP MAX_EXP MIN MIN_10_EXP MIN_EXP PI
            \ RADIX ROUNDS Scalar Unify abs abs2 acos acos! acosh acosh!
            \ ancestors angle arg asin asin! asinh asinh! atan atan! atan2
            \ atan2! atanh atanh! between? ceil chr column column_size
            \ column_vectors compare_by compare_by_row_vectors conj
            \ conjugate cos cos! cosh cosh! covector denominator det
            \ determinant div divmod downto dup each2 eql? eqn? equal? erf
            \ erfc exp exp! extend finite? floor frexp frozen? gcd gcd2
            \ gcdlcm hypot im imag image infinite? inner_product integer?
            \ inv inverse inverse_from is_a? kind_of? lcm ldexp log log!
            \ log10 log10! minor modulo nan? next nil? nonzero? numerator
            \ polar power! power2 prec prec_f prec_i prime_division quo r
            \ rank real regular? remainder round row row_size row_vectors
            \ rsqrt sin sin! singular? sinh sinh! sqrt sqrt! square? step
            \ succ t tan tan! tanh tanh! times transpose truncate upto
            \ zero?

syntax match TCalcDefWord /\(:\w\+\ze\(\s\|$\)\|\(^\|\s\)\zs;\)/
syntax match TCalcOperations /[+*/%\<>=!^-]\+/
syntax match TCalcNumeric /[+-]\?\d\S*/
syntax match TCalcArgument /\w\+:\S\+/ contained containedin=TCalcBlock
syntax region TCalcString start=/"/ end=/"/ skip=/\\"/
syntax region TCalcComment start=/\/\*/ end=/\*\//

syntax region TCalcLambda matchgroup=PreProc start=/((/ end=/)/ transparent
syntax region TCalcBlock matchgroup=PreProc start=/(/ end=/)/ transparent
syntax region TCalcArray matchgroup=Delimiter start=/\[/ end=/\]/ transparent

HiLink TCalcDefWord Special
HiLink TCalcWords Statement
HiLink TCalcString Constant
HiLink TCalcOperations Statement
HiLink TCalcNumeric Constant
HiLink TCalcArgument Type
HiLink TCalcComment Comment


delcommand HiLink
let b:current_syntax = 'tcalc'

