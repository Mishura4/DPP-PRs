/************************************************************************************
 *
 * D++, A Lightweight C++ library for Discord
 *
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2021 Craig Edwards and D++ contributors 
 * (https://github.com/brainboxdotcc/DPP/graphs/contributors)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ************************************************************************************/

module;

#include <dpp/export.h>
#include <dpp/compat.h>

#if !defined (DPP_IMPORT_STD)
	#define DPP_IMPORT_STD 0
#endif

#if !defined (DPP_IMPORT_NLOHMANN)
	#define DPP_IMPORT_NLOHMANN 0
#endif

#if !DPP_IMPORT_STD
    // Include the entire standard library so it doesn't cause issue in our headers
	#include <cstddef>
	#include <cstdint>
	#include <cstring>
	#include <ctime>

	#include <algorithm>
	#include <charconv>
	#include <condition_variable>
	#include <cstddef>
	#include <ctime>
	#include <deque>
	#include <exception>
	#include <fstream>
	#include <functional>
	#include <iomanip>
	#include <iostream>
	#include <locale>
	#include <map>
	#include <memory>
	#include <mutex>
	#include <optional>
	#include <queue>
	#include <shared_mutex>
	#include <sstream>
	#include <string>
	#include <string_view>
	#include <thread>
	#include <type_traits>
	#include <unordered_map>
	#include <variant>
	#include <vector>
#endif

#if !DPP_IMPORT_NLOHMANN
	#include <nlohmann/json.hpp>
#endif

export module dpp;

// Allow the user to provide their own module names (i.e. with CMake shenanigans)
#if DPP_IMPORT_STD
	#ifndef DPP_STD_MODULE
		#define DPP_STD_MODULE std
	#endif
	#ifndef DPP_STD_COMPAT_MODULE
		#define DPP_STD_COMPAT_MODULE std.compat
	#endif

	import DPP_STD_MODULE;
	import DPP_STD_COMPAT_MODULE;
#endif

#if DPP_IMPORT_NLOHMANN
	#ifndef DPP_NLOHMANN_MODULE
		#define DPP_NLOHMANN_MODULE nlohmann.json
	#endif
	import DPP_NLOHMANN_MODULE;
#endif

export extern "C++"
{

#include "dpp/dpp.h"

}
