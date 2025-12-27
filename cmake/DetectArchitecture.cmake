include(CheckCXXSourceRuns)

if(${AVX_TYPE} STREQUAL "OFF")
	function(check_instruction_set INSTRUCTION_SET_NAME INSTRUCTION_SET_FLAG INSTRUCTION_SET_INTRINSIC)

		set(INSTRUCTION_SET_CODE "
		 #if defined(__arm__) || defined(__aarch64__)
			#include <arm_neon.h>
		 #else
			#include <immintrin.h>
			#include <stdint.h>
		 #endif

			int main()
			{
				${INSTRUCTION_SET_INTRINSIC};
				return 0;
			}
		")

		set(CMAKE_REQUIRED_FLAGS "${INSTRUCTION_SET_FLAG}")
		CHECK_CXX_SOURCE_RUNS("${INSTRUCTION_SET_CODE}" "${INSTRUCTION_SET_NAME}")
		if(${INSTRUCTION_SET_NAME})
			set(AVX_TYPE "${INSTRUCTION_SET_NAME}" PARENT_SCOPE)
			set(AVX_FLAG "${INSTRUCTION_SET_FLAG}" PARENT_SCOPE)
		else()
			return()
		endif()
	endfunction()

	if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
		set(INSTRUCTION_SETS
			"AVX1?/arch:AVX?__m128i value{}#auto result = _mm_extract_epi32(value, 0)"
			"AVX2?/arch:AVX2?__m256i value{}#auto result = _mm256_add_epi32(__m256i{}, __m256i{})"
			"AVX512?/arch:AVX512?int32_t result[16]#const _mm512i& value{}#_mm512_store_si512(result, value)"
			"AVX1024??uint8x16_t mask{ 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F }#vandq_u8(mask, mask)"
		)
	else()
		set(INSTRUCTION_SETS
			"AVX1?-mavx?__m128i value{}#auto result = _mm_extract_epi32(value, 0)"
			"AVX2?-mavx2?__m256i value{}#auto result = _mm256_add_epi32(__m256i{}, __m256i{})"
			"AVX512?-mavx512f?int32_t result[16]#const _mm512i& value{}#_mm512_store_si512(result, value)"
			"AVX1024??uint8x16_t mask{ 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F }#vandq_u8(mask, mask)"
	)
	endif()

	set(CMAKE_REQUIRED_FLAGS_SAVE "${CMAKE_REQUIRED_FLAGS}")

	set(AVX_TYPE "AVX0")
	set(AVX_TYPE "AVX0" PARENT_SCOPE)
	set(AVX_FLAGS "" PARENT_SCOPE)

	# This is only supported on x86/x64, it is completely skipped and forced to T_fallback anywhere else
	if ((${CMAKE_SYSTEM_PROCESSOR} MATCHES "x86_64") OR (${CMAKE_SYSTEM_PROCESSOR} MATCHES "i386") OR (${CMAKE_SYSTEM_PROCESSOR} MATCHES "AMD64") OR (${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "arm64") OR (${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "armv7l"))

		foreach(INSTRUCTION_SET IN LISTS INSTRUCTION_SETS)
			string(REPLACE "?" ";" CURRENT_LIST "${INSTRUCTION_SET}")
			list(GET CURRENT_LIST 0 INSTRUCTION_SET_NAME)
			list(GET CURRENT_LIST 1 INSTRUCTION_SET_FLAG)
			string(REPLACE "." ";" INSTRUCTION_SET_FLAG "${INSTRUCTION_SET_FLAG}")
			list(GET CURRENT_LIST 2 INSTRUCTION_SET_INTRINSIC)
			string(REPLACE "#" ";" INSTRUCTION_SET_INTRINSIC "${INSTRUCTION_SET_INTRINSIC}")
			check_instruction_set("${INSTRUCTION_SET_NAME}" "${INSTRUCTION_SET_FLAG}" "${INSTRUCTION_SET_INTRINSIC}")
		endforeach()

		message(STATUS "Detected ${CMAKE_SYSTEM_PROCESSOR} AVX type: ${AVX_TYPE} (FLAGS: ${AVX_FLAG})")
		set(AVX_TYPE ${AVX_TYPE})
		set(AVX_TYPE ${AVX_TYPE} PARENT_SCOPE)
		set(AVX_FLAG ${AVX_FLAG} PARENT_SCOPE)
		set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS_SAVE}")
	else()
		message(STATUS "AVX not supported by architecture ${CMAKE_SYSTEM_PROCESSOR} ${AVX_TYPE}")
		set(AVX_TYPE "AVX0")
		set(AVX_FLAG "" PARENT_SCOPE)
		set(AVX_TYPE "AVX0" PARENT_SCOPE)
	endif()
else()
	message("-- AVX type overridden by configuration: ${AVX_TYPE}")
endif()


if(WIN32 AND NOT MINGW AND NOT DPP_CLANG_CL)
	if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
		if(NOT DPP_MODULE) # Allow force override
			if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS_EQUAL 19.44.35000) # Arbitrary number based on vibes
				message("-- ${Yellow}MSVC appears old - disabling C++20 modules${ColourReset}")
				set(DPP_NO_MODULE ON)
			endif()
		endif ()
		if (NOT DPP_NO_CORO)
			if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS_EQUAL 19.29.30158) # Taken from 2019 actions, as they seemingly fail to compile.
				message("${BoldRed}Coroutines with MSVC (Visual Studio) require VS 2022 (Compiler Ver: 19.29.30158) or above. Forcing coroutines off.${ColourReset}")
				set(DPP_NO_CORO ON)
			endif()
		endif ()
	endif()
else()
	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		message("-- ${Yellow}Clang - attempting to detect if using libc++ or stdc++${ColourReset}")
		check_cxx_source_compiles("
			#include <iostream>

			int a =
			#ifdef __GLIBCXX__
				1;
			#else
				fgsfds;
			#endif

			int main(int argc, char* argv[])
			{
				return 0;
			}
			" IS_GLIBCXX)
		if(NOT DPP_MODULE) # Allow force override
			if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 21.0.0)
				message("-- ${Yellow}Clang < 21 - disabling C++20 modules")
				set(DPP_NO_MODULE ON)
			endif ()
		endif()
		if (NOT DPP_NO_CORO)
			if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 14.0.0) # clang >= 14 has native support
				if(IS_GLIBCXX)
					if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 12.0.0)
						message("${BoldRed}Clang with stdc++ and coroutines requires version 12.0.0 or above. Forcing coroutines off.${ColourReset}")
						set(DPP_NO_CORO ON)
					else()
						message("-- ${Yellow}Detected stdc++ - enabling mock std::experimental namespace${ColourReset}")
						target_compile_definitions(dpp PUBLIC "STDCORO_GLIBCXX_COMPAT" "DPP_CORO")
					endif()
				else()
					message("-- ${Yellow}Detected libc++ - using <experimental/coroutine>${ColourReset}")
					if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0.0)
						set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcoroutines-ts")
					endif()
					target_compile_definitions(dpp PUBLIC "STDCORO_GLIBCXX_COMPAT" "DPP_CORO")
				endif()
				message("-- ${Yellow}Note - coroutines in clang < 14 are experimental, upgrading is recommended${ColourReset}")
			endif()
		endif ()
	elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
		if (NOT DPP_MODULE)
			if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 15.0)
				message("-- ${Yellow}g++ < 15 - disabling C++20 modules")
				set(DPP_NO_MODULE ON)
			endif ()
		endif ()
		if (NOT DPP_NO_CORO)
			if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 10.0)
				message("${BoldRed}Coroutines with g++ require version 10 or above. Forcing coroutines off.${ColourReset}")
				set(DPP_NO_CORO ON)
			elseif(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 11.0)
				message("-- ${Yellow}Note - coroutines in g++10 are experimental, upgrading to g++11 or above is recommended${ColourReset}")
				set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcoroutines")
				target_compile_definitions(dpp PUBLIC "STDCORO_GLIBCXX_COMPAT" "DPP_CORO")
			endif()
		endif ()
	endif()
endif()
