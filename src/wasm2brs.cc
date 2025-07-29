/*
  Copyright 2020 Trevor Sundberg
  This file has been modified to output BrightScript
  All modifications are licenced under LICENSE.md
*/
/*
 * Copyright 2017 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <cassert>
#include <cinttypes>
#include <cstdio>
#include <cstdlib>

#include "wabt/apply-names.h"
#include "wabt/binary-reader-ir.h"
#include "wabt/binary-reader.h"
#include "wabt/error-formatter.h"
#include "wabt/feature.h"
#include "wabt/filenames.h"
#include "wabt/generate-names.h"
#include "wabt/ir.h"
#include "wabt/option-parser.h"
#include "wabt/result.h"
#include "wabt/stream.h"
#include "wabt/validator.h"
#include "wabt/wast-lexer.h"

#include "brs-writer.h"

using namespace wabt;

static int s_verbose;
static std::string s_infile;
static WriteCOptions s_write_c_options;
static bool s_read_debug_names = true;
static std::unique_ptr<FileStream> s_log_stream;

static const char s_description[] =
    R"(  Read a file in the WebAssembly binary format, and convert it to
  a BrightScript source file.

examples:
  # parse binary file test.wasm and write test.brs
  $ wasm2brs test.wasm -o test.brs
)";

// For now, we don't support any features, so this is empty.
static const std::vector<std::string> supported_features = {};

static bool IsFeatureSupported(const std::string& feature) {
  return std::find(std::begin(supported_features), std::end(supported_features),
                   feature) != std::end(supported_features);
};

static void ParseOptions(int argc, char** argv) {
  OptionParser parser("wasm2brs", s_description);

  parser.AddOption('v', "verbose", "Use multiple times for more info", []() {
    s_verbose++;
    s_log_stream = FileStream::CreateStderr();
  });
  parser.AddOption(
      'o', "output", "FILENAME",
      "Output file for the generated BrightScript source file, by default use stdout",
      [](const char* argument) {
        s_write_c_options.out_filename = argument;
        ConvertBackslashToSlash(&s_write_c_options.out_filename);
      });
  s_write_c_options.features.AddOptions(&parser);
  parser.AddOption("no-debug-names", "Ignore debug names in the binary file",
                   []() { s_read_debug_names = false; });
  parser.AddArgument("filename", OptionParser::ArgumentCount::One,
                     [](const char* argument) {
                       s_infile = argument;
                       ConvertBackslashToSlash(&s_infile);
                     });
  parser.AddOption('n', "name-prefix", "NAMEPREFIX", "The prefix to use on all function and variable names",
                     [](const char* argument) {
                       s_write_c_options.name_prefix = argument;
                     });
  parser.Parse(argc, argv);

  bool any_non_supported_feature = false;
#define WABT_FEATURE(variable, flag, default_, help)                   \
  any_non_supported_feature |=                                         \
      (s_write_c_options.features.variable##_enabled() != default_) && \
      s_write_c_options.features.variable##_enabled() &&               \
      !IsFeatureSupported(flag);
#include "wabt/feature.def"
#undef WABT_FEATURE

  if (any_non_supported_feature) {
    fprintf(stderr,
            "wasm2c currently only supports a limited set of features.\n");
    exit(1);
  }
}

Result Wasm2BrsMain(Errors& errors) {
  std::vector<uint8_t> file_data;
  CHECK_RESULT(ReadFile(s_infile.c_str(), &file_data));

  Module module;
  const bool kStopOnFirstError = true;
  const bool kFailOnCustomSectionError = true;
  ReadBinaryOptions options(s_write_c_options.features, s_log_stream.get(),
                            s_read_debug_names, kStopOnFirstError,
                            kFailOnCustomSectionError);
  CHECK_RESULT(ReadBinaryIr(s_infile.c_str(), file_data.data(),
                            file_data.size(), options, &errors, &module));
  CHECK_RESULT(ValidateModule(&module, &errors, s_write_c_options.features));
  CHECK_RESULT(GenerateNames(&module));
  /* TODO(binji): This shouldn't fail; if a name can't be applied
   * (because the index is invalid, say) it should just be skipped. */
  ApplyNames(&module);

  if (s_write_c_options.name_prefix.empty()) {
    if (module.name.empty()) {
      s_write_c_options.name_prefix = "w2b";
    } else {
      s_write_c_options.name_prefix = module.name;
    }
  }

  CHECK_RESULT(WriteBrs(&module, s_write_c_options));

  return Result::Ok;
}

int ProgramMain(int argc, char** argv) {
  Result result;

  InitStdio();
  ParseOptions(argc, argv);

  Errors errors;
  result = Wasm2BrsMain(errors);
  FormatErrorsToFile(errors, Location::Type::Binary);

  return result != Result::Ok;
}

int main(int argc, char** argv) {
  WABT_TRY
  return ProgramMain(argc, argv);
  WABT_CATCH_BAD_ALLOC_AND_EXIT
}
