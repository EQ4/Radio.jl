using Base.Test
using Multirate





#==============================================================================#
#               ____ _ _  _ ____ _    ____    ____ ____ ___ ____               #
#               [__  | |\ | | __ |    |___    |__/ |__|  |  |___               #
#               ___] | | \| |__] |___ |___    |  \ |  |  |  |___               #
#==============================================================================#

function short_singlerate_test( h, x, dlyLine )
    
    @printf( "Radio's Single-rate filt\n\t")
    @time nativeResult = filt( h, x, dlyLine )
    
    self = FIRFilter( h )    
    @printf( "Stateful Single-rate filt\n\t")
    @time y = append!( filt( self, x[1:250] ) , filt( self, x[251:end] ) )

    @printf( "Base Single-rate filt\n\t")
    @time baseResult   = Base.filt( h, 1.0, x )


    areApprox( nativeResult, baseResult ) && areApprox( y, baseResult )    
end

#=============================
h = rand( 56 )
x = rand( 1_000_000 )
dlyLine = zeros( length(h) - 1 )

short_singlerate_test( h, x, dlyLine )
=============================#




#==============================================================================#
#                      ___  ____ ____ _ _  _ ____ ___ ____                     #
#                      |  \ |___ |    | |\/| |__|  |  |___                     #
#                      |__/ |___ |___ | |  | |  |  |  |___                     #
#==============================================================================#


function test_decimate{Th, Tx}( ::Type{Th}, ::Type{Tx}, hLen, xLen, factor )
    h = rand( Th, hLen )
    x = rand( Tx, xLen )
    

    nativeResult = decimate( h, x, factor )
    baseResult   = Base.filt( h, one(Th), x )
    baseResult   = baseResult[1:factor:end]
    areApprox( nativeResult, baseResult )
end



function short_decimate_test( h, x, factor, step )
    xLen = length(x)
    # @printf( "\nRadio's decimation\n\t")
    # @time nativeResult = decimate( h, x, factor )
    # display( nativeResult )
    #
    # self = FIRFilter( h, 1//factor )
    # @printf( "\nDlyLineful decimation\n\t")
    # @time begin
    #     y1   = filt( self, x[1:8])
    #     y2   = filt( self, x[9:100] )
    # end
    # dlyLinefulResult = [y1, y2]
    # display( dlyLinefulResult )
    #
    # @printf( "\nNaive resampling\n\t")
    # @time begin
        baseResult = Base.filt( h, one(x[1]), x )[1:factor:end]
    # end
    # display( baseResult )
    #
    # areApprox( dlyLinefulResult, baseResult ) & areApprox( nativeResult, baseResult ) ? println( "Tests passed" ) : println( "1 or more tests failed")
    self      = FIRFilter( h, 1//factor )
    incrementalResult = similar(x, 0)
    for i in 1:step:xLen
        xNext = x[i : min(i+step-1, xLen)]
        append!( incrementalResult, filt( self, xNext ) )
        println( "incrementalResult = $(incrementalResult.') ")
    end
    # println()
    # println()
    
    # minLen = min( length(baseResult), length( incrementalResult ) )
    
    # println( "baseResult   = $(baseResult.')" )
    # println( "nativeResult = $(incrementalResult.')" )
    
    display( [ baseResult incrementalResult ])
    
    passed = areApprox( baseResult, incrementalResult )
    # println( "Passed = $passed" )

    return passed
end

#===================================
h          = Float64[1:10];
x          = Float64[1:26];
factor     = 5;
testPassed = falses( length(x) );


for chunkSize = 1:length(x)
    thisTestPassed = short_decimate_test( h, x, factor, chunkSize )
    testPassed[chunkSize] = thisTestPassed || error()
end
display( testPassed )
===================================#



#==============================================================================#
#               _ _  _ ___ ____ ____ ___  _    ____ ____ ___ ____              #
#               | |\ |  |  |___ |__/ |__] |    |  | |__|  |  |___              #
#               | | \|  |  |___ |  \ |    |___ |__| |  |  |  |___              #
#==============================================================================#

function test_interpolate{Th, Tx}( ::Type{Th}, ::Type{Tx}, hLen, xLen, factor )
    h = rand( Th, hLen )
    h = isreal(h[1]) ? h : real(h).+im
    x = rand( Tx, xLen )
    xx = upsample( x, factor )
    
    nativeResult = interpolate( h, x, factor )
    baseResult   = Base.filt( h, one(Th), xx )
    areApprox( nativeResult, baseResult )
end


function short_interpolate_test( h, x, factor )    
    @printf( "Radio's interpolate\n\t")
    @time nativeResult = interpolate( h, x, factor )
    @printf( "Naive interpolate\n\t")
    @time begin
        xx = zeros( length(x) * factor )
        for n = 0:length(x)-1;
            xx[ n*factor+1 ] = x[ n+1 ]
        end
        baseResult = Base.filt( h, 1.0, xx )        
    end
        
    areApprox( nativeResult, baseResult )
end

#=============================
h = rand( 56 )
x = rand( 1_000_000 )
factor = 4

short_interpolate_test( h, x, factor )
=============================#


#==============================================================================#
#           ____ ____ ___     ____ ____ ____ ____ _  _ ___  _    ____          #
#           |__/ |__|  |      |__/ |___ [__  |__| |\/| |__] |    |___          #
#           |  \ |  |  |  .   |  \ |___ ___] |  | |  | |    |___ |___          #
#==============================================================================#

function short_rational_test( h, x, ratio )
    upfactor   = num( ratio )
    downfactor = den( ratio )
    
    @printf( "Radio's rational resampling\n\t")
    @time nativeResult = resample( h, x, upfactor//downfactor );
    
    @printf( "Naive resampling\n\t")
    @time begin
        xx         = zeros( length(x) * upfactor );
        baseResult = similar( x, int( length(x) * upfactor / downfactor ))
        
        for n = 0:length(x)-1;
            xx[ n*upfactor+1 ] = x[ n+1 ];
        end
        
        baseResultInterpolated = Base.filt( h, 1.0, xx );
        baseResult = [ baseResultInterpolated[n] for n = 1:downfactor:length( baseResultInterpolated ) ]
    end
    
    [ baseResult nativeResult ]
    areApprox( nativeResult, baseResult )
end

#=========================
ratio = 3//4
h     = rand( 56 )
x     = rand( 1000000 )
short_rational_test( h, x, ratio )
=========================#
