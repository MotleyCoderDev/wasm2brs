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

#include "brs-writer.h"

#include <cctype>
#include <cinttypes>
#include <map>
#include <set>
#include <iostream>

#include "src/cast.h"
#include "src/common.h"
#include "src/ir.h"
#include "src/literal.h"
#include "src/stream.h"
#include "src/string-view.h"

#define INDENT_SIZE 2

#define BRS_ABORT(x) (std::cerr << __FILE__ << "(" << __LINE__ << ") in " << __FUNCTION__ << ": " << x), abort()
#define BRS_UNREACHABLE BRS_ABORT("Unreachable")

namespace wabt {

namespace {

class VarHasher {
public:
  size_t operator() (const Var& key) const {
      return key.is_index()
        ? std::hash<Index>()(key.index())
        : std::hash<std::string>()(key.name());
  }
};

class VarEqual {
public:
  bool operator() (const Var& t1, const Var& t2) const {
    return  &t1 == &t2 ||
            t1.type() == t2.type() &&
            (t1.is_index()
              ? t1.index() == t2.index()
              : t1.name() == t2.name());
  }
};

struct Label {
  Label(LabelType label_type,
        const std::string& name,
        const TypeVector& sig,
        size_t type_stack_size,
        bool used = false)
      : label_type(label_type),
        name(name),
        sig(sig),
        type_stack_size(type_stack_size),
        used(used) {}

  bool HasValue() const {
    return label_type != LabelType::Loop && !sig.empty();
  }

  LabelType label_type;
  const std::string& name;
  const TypeVector& sig;
  size_t type_stack_size;
  bool used = false;
};

template <int>
struct Name {
  explicit Name(const std::string& name) : name(name) {}
  const std::string& name;
};

typedef Name<0> LocalName;
typedef Name<1> GlobalName;
typedef Name<2> ExternalPtr;
typedef Name<3> ExternalRef;

struct GotoLabel {
  explicit GotoLabel(const Var& var) : var(var) {}
  const Var& var;
};

struct LabelDecl {
  explicit LabelDecl(const std::string& name) : name(name) {}
  std::string name;
};

struct GlobalVar {
  explicit GlobalVar(const Var& var) : var(var) {}
  const Var& var;
};

struct StackVar {
  explicit StackVar(Index index, Type type = Type::Any)
      : index(index), type(type) {}
  Index index;
  Type type;
};

struct TypeEnum {
  explicit TypeEnum(Type type) : type(type) {}
  Type type;
};

struct SignedType {
  explicit SignedType(Type type) : type(type) {}
  Type type;
};

struct ResultType {
  explicit ResultType(const TypeVector& types) : types(types) {}
  const TypeVector& types;
};

struct Newline {};
struct OpenBrace {};
struct CloseBrace {};

int GetShiftMask(Type type) {
  switch (type) {
    case Type::I32: return 31;
    case Type::I64: return 63;
    default: BRS_UNREACHABLE; return 0;
  }
}

class CWriter {
 public:
  CWriter(Stream* stream,
          const WriteCOptions& options)
      : options_(options),
        brs_stream_(stream) {
    options_.name_prefix = LegalizeNameNoAddons(options_.name_prefix);
  }

  Result WriteModule(const Module&);

 private:
  typedef std::set<std::string> SymbolSet;
  typedef std::map<std::string, std::string> SymbolMap;
  typedef std::pair<Index, Type> StackTypePair;
  typedef std::map<StackTypePair, std::string> StackVarSymbolMap;

  void UseStream(Stream*);

  void WriteCSource();

  size_t MarkTypeStack() const;
  void ResetTypeStack(size_t mark);
  Type StackType(Index) const;
  void PushType(Type);
  void PushTypes(const TypeVector&);
  void DropTypes(size_t count);

  void PushLabel(LabelType,
                 const std::string& name,
                 const FuncSignature&,
                 bool used = false);
  const Label* FindLabel(const Var& var);
  bool IsTopLabelUsed() const;
  void PopLabel();

  static std::string AddressOf(const std::string&);
  static std::string Deref(const std::string&);

  static char MangleType(Type);
  static std::string LegalizeNameNoAddons(string_view);
  std::string LegalizeName(const std::string& prefix, const std::string& module_name, string_view name);
  std::string DefineName(SymbolSet*, string_view, const std::string& prefix = std::string());
  std::string DefineImportName(const std::string& name,
                               string_view module_name,
                               string_view mangled_field_name);
  std::string DefineGlobalScopeName(const std::string&, const std::string& prefix = std::string());
  std::string DefineLocalScopeName(const std::string&);
  std::string DefineStackVarName(Index, Type, string_view);

  void Indent(int size = INDENT_SIZE);
  void Dedent(int size = INDENT_SIZE);
  void WriteIndent();
  void WriteData(const void* src, size_t size);
  void Writef(const char* format, ...);

  template <typename T, typename U, typename... Args>
  void Write(T&& t, U&& u, Args&&... args) {
    Write(std::forward<T>(t));
    Write(std::forward<U>(u));
    Write(std::forward<Args>(args)...);
  }

  std::string GetGlobalName(const std::string&) const;

  void Write() {}
  void Write(Newline);
  void Write(OpenBrace);
  void Write(CloseBrace);
  void Write(Index);
  void Write(string_view);
  void Write(const LocalName&);
  void Write(const GlobalName&);
  void Write(const ExternalPtr&);
  void Write(const ExternalRef&);
  void Write(Type);
  void Write(SignedType);
  void Write(TypeEnum);
  void Write(const Var&);
  void Write(const GotoLabel&);
  void Write(const LabelDecl&);
  void WriteLabelRaw(const LabelDecl&);
  void Write(const GlobalVar&);
  void Write(const StackVar&);
  void Write(const ResultType&);
  void Write(const Const&);
  void WriteInitExpr(const ExprList&);
  std::string GenerateHeaderGuard() const;
  void WriteSourceTop();
  void WriteFuncTypes();
  void WriteImports();
  void WriteFuncDeclarations();
  void WriteFuncDeclaration(const FuncDeclaration&, const std::string&);
  void WriteGlobals();
  void WriteGlobal(const Global&, const std::string&);
  void WriteMemories();
  void WriteMemory(const std::string&);
  void WriteTables();
  void WriteTable(const std::string&);
  void WriteDataInitializers();
  void WriteElemInitializers();
  void WriteInitExports();
  void WriteExports();
  void WriteInit();
  void WriteFuncs();
  void Write(const Func&);
  void WriteParams(const std::vector<std::string>& index_to_name);
  void WriteLocals(const std::vector<std::string>& index_to_name);
  void WriteStackVarDeclarations();
  void Write(const ExprList&);

  enum class AssignOp {
    Disallowed,
    Allowed,
  };

  void WriteSimpleUnaryExpr(Opcode, const char* op);
  void WriteInfixBinaryExpr(Opcode,
                            const char* op,
                            AssignOp = AssignOp::Allowed);
  void WritePrefixBinaryExpr(Opcode, const char* op);
  void WriteSignedBinaryExpr(Opcode, const char* op);
  void Write(const BinaryExpr&);
  void Write(const CompareExpr&);
  void Write(const ConvertExpr&);
  void Write(const LoadExpr&);
  void Write(const StoreExpr&);
  void Write(const UnaryExpr&);
  void Write(const TernaryExpr&);
  void Write(const SimdLaneOpExpr&);
  void Write(const SimdShuffleOpExpr&);
  void Write(const LoadSplatExpr&);

  WriteCOptions options_;
  const Module* module_ = nullptr;
  const Func* func_ = nullptr;
  size_t label_count_ = 0;
  Stream* stream_ = nullptr;
  MemoryStream func_stream_;
  Stream* brs_stream_ = nullptr;
  Result result_ = Result::Ok;
  int indent_ = 0;
  bool should_write_indent_next_ = false;

  SymbolMap global_sym_map_;
  SymbolMap local_sym_map_;
  StackVarSymbolMap stack_var_sym_map_;
  SymbolSet global_syms_;
  SymbolSet local_syms_;
  SymbolSet import_syms_;
  TypeVector type_stack_;
  std::vector<Label> label_stack_;
};

static const char kImplicitFuncLabel[] = "$Bfunc";

#define SECTION_NAME(x) s_header_##x
#include "src/prebuilt/wasm2c.include.h"
#undef SECTION_NAME

#define SECTION_NAME(x) s_source_##x
#include "src/prebuilt/wasm2c.include.c"
#undef SECTION_NAME

size_t CWriter::MarkTypeStack() const {
  return type_stack_.size();
}

void CWriter::ResetTypeStack(size_t mark) {
  assert(mark <= type_stack_.size());
  type_stack_.erase(type_stack_.begin() + mark, type_stack_.end());
}

Type CWriter::StackType(Index index) const {
  assert(index < type_stack_.size());
  return *(type_stack_.rbegin() + index);
}

void CWriter::PushType(Type type) {
  type_stack_.push_back(type);
}

void CWriter::PushTypes(const TypeVector& types) {
  type_stack_.insert(type_stack_.end(), types.begin(), types.end());
}

void CWriter::DropTypes(size_t count) {
  assert(count <= type_stack_.size());
  type_stack_.erase(type_stack_.end() - count, type_stack_.end());
}

void CWriter::PushLabel(LabelType label_type,
                        const std::string& name,
                        const FuncSignature& sig,
                        bool used) {
  // TODO(binji): Add multi-value support.
  if ((label_type != LabelType::Func && sig.GetNumParams() != 0)) {
    BRS_ABORT("Unsupported multiple values: label_type " << (int)label_type << ", params " << sig.GetNumParams());
  }

  label_stack_.emplace_back(label_type, name, sig.result_types,
                            type_stack_.size(), used);
}

const Label* CWriter::FindLabel(const Var& var) {
  Label* label = nullptr;

  if (var.is_index()) {
    // We've generated names for all labels, so we should only be using an
    // index when branching to the implicit function label, which can't be
    // named.
    assert(var.index() + 1 == label_stack_.size());
    label = &label_stack_[0];
  } else {
    assert(var.is_name());
    for (Index i = label_stack_.size(); i > 0; --i) {
      label = &label_stack_[i - 1];
      if (label->name == var.name())
        break;
    }
  }

  assert(label);
  label->used = true;
  return label;
}

bool CWriter::IsTopLabelUsed() const {
  assert(!label_stack_.empty());
  return label_stack_.back().used;
}

void CWriter::PopLabel() {
  label_stack_.pop_back();
}

// static
std::string CWriter::AddressOf(const std::string& s) {
  return s;
}

// static
std::string CWriter::Deref(const std::string& s) {
  return s;
}

// static
char CWriter::MangleType(Type type) {
  switch (type) {
    case Type::I32: return 'i';
    case Type::I64: return 'j';
    case Type::F32: return 'f';
    case Type::F64: return 'd';
    default:
      BRS_UNREACHABLE;
      return '_';
  }
}

std::string CWriter::LegalizeNameNoAddons(string_view name) {
  std::string result;
  for (size_t i = 0; i < name.size(); ++i)
    result += isalnum(name[i]) ? tolower(name[i]) : '_';
  return result;
}

uint32_t adler32(const uint8_t* data, size_t len) {
  const uint32_t MOD_ADLER = 65521;
  uint32_t a = 1, b = 0;
  for (size_t i = 0; i < len; ++i) {
    a = (a + data[i]) % MOD_ADLER;
    b = (b + a) % MOD_ADLER;
  }
  return (b << 16) | a;
}

std::string CWriter::LegalizeName(const std::string& prefix, const std::string& module_name, string_view name) {
  const std::string legalized = LegalizeNameNoAddons(name);
  const std::string module_prefix = module_name == "env" ? "" : module_name + "_";
  const std::string output = prefix + module_prefix + legalized;
  return legalized == name
    ? output
    : output + "_" + std::to_string(adler32((const uint8_t*)name.begin(), name.length()));
}

std::string CWriter::DefineName(SymbolSet* set, string_view name, const std::string& prefix) {
  std::string legal = LegalizeName(prefix, options_.name_prefix, name);
  if (set->find(legal) != set->end()) {
    std::string base = legal + "_";
    size_t count = 0;
    do {
      legal = base + std::to_string(count++);
    } while (set->find(legal) != set->end());
  }
  set->insert(legal);
  return legal;
}

string_view StripLeadingDollar(string_view name) {
  if (!name.empty() && name[0] == '$') {
    name.remove_prefix(1);
  }
  return name;
}

std::string CWriter::DefineImportName(const std::string& name,
                                      string_view module,
                                      string_view mangled_field_name) {
  std::string mangled = mangled_field_name.to_string();
  import_syms_.insert(name);
  global_syms_.insert(mangled);
  global_sym_map_.insert(SymbolMap::value_type(name, mangled));
  return mangled;
}

std::string CWriter::DefineGlobalScopeName(const std::string& name, const std::string& prefix) {
  std::string unique = DefineName(&global_syms_, StripLeadingDollar(name), prefix);
  global_sym_map_.insert(SymbolMap::value_type(name, unique));
  return unique;
}

std::string CWriter::DefineLocalScopeName(const std::string& name) {
  std::string unique = DefineName(&local_syms_, StripLeadingDollar(name));
  local_sym_map_.insert(SymbolMap::value_type(name, unique));
  return unique;
}

std::string CWriter::DefineStackVarName(Index index,
                                        Type type,
                                        string_view name) {
  std::string unique = DefineName(&local_syms_, name);
  StackTypePair stp = {index, type};
  stack_var_sym_map_.insert(StackVarSymbolMap::value_type(stp, unique));
  return unique;
}

void CWriter::Indent(int size) {
  indent_ += size;
}

void CWriter::Dedent(int size) {
  indent_ -= size;
  assert(indent_ >= 0);
}

void CWriter::WriteIndent() {
  static char s_indent[] =
      "                                                                       "
      "                                                                       ";
  static size_t s_indent_len = sizeof(s_indent) - 1;
  size_t to_write = indent_;
  while (to_write >= s_indent_len) {
    stream_->WriteData(s_indent, s_indent_len);
    to_write -= s_indent_len;
  }
  if (to_write > 0) {
    stream_->WriteData(s_indent, to_write);
  }
}

void CWriter::WriteData(const void* src, size_t size) {
  if (should_write_indent_next_) {
    WriteIndent();
    should_write_indent_next_ = false;
  }
  stream_->WriteData(src, size);
}

void WABT_PRINTF_FORMAT(2, 3) CWriter::Writef(const char* format, ...) {
  WABT_SNPRINTF_ALLOCA(buffer, length, format);
  WriteData(buffer, length);
}

void CWriter::Write(Newline) {
  Write("\n");
  should_write_indent_next_ = true;
}

void CWriter::Write(OpenBrace) {
  Indent();
  Write(Newline());
}

void CWriter::Write(CloseBrace) {
  Dedent();
}

void CWriter::Write(Index index) {
  Writef("%" PRIindex, index);
}

void CWriter::Write(string_view s) {
  WriteData(s.data(), s.size());
}

void CWriter::Write(const LocalName& name) {
  assert(local_sym_map_.count(name.name) == 1);
  Write(local_sym_map_[name.name]);
}

std::string CWriter::GetGlobalName(const std::string& name) const {
  if (global_sym_map_.count(name) != 1) {
    std::cout << "########################## Invalid GetGlobalName: " << name << std::endl << std::flush;
    return "BAD_" + name;
  }
  assert(global_sym_map_.count(name) == 1);
  auto iter = global_sym_map_.find(name);
  assert(iter != global_sym_map_.end());
  return iter->second;
}

void CWriter::Write(const GlobalName& name) {
  Write(GetGlobalName(name.name));
}

void CWriter::Write(const ExternalPtr& name) {
  bool is_import = import_syms_.count(name.name) != 0;
  if (is_import) {
    Write(GetGlobalName(name.name));
  } else {
    Write(AddressOf(GetGlobalName(name.name)));
  }
}

void CWriter::Write(const ExternalRef& name) {
  Write(GetGlobalName(name.name));
}

void CWriter::Write(const Var& var) {
  assert(var.is_name());
  Write(LocalName(var.name()));
}

void CWriter::Write(const GotoLabel& goto_label) {
  const Label* label = FindLabel(goto_label.var);
  if (label->HasValue()) {
    assert(label->sig.size() == 1);
    assert(type_stack_.size() >= label->type_stack_size);
    Index dst = type_stack_.size() - label->type_stack_size - 1;
    if (dst != 0)
      Write(StackVar(dst, label->sig[0]), " = ", StackVar(0), Newline());
  }

  if (goto_label.var.is_name()) {
    Write("Goto ", goto_label.var);
  } else {
    // We've generated names for all labels, so we should only be using an
    // index when branching to the implicit function label, which can't be
    // named.
    Write("Goto ", Var(kImplicitFuncLabel));
  }
}

void CWriter::Write(const LabelDecl& label) {
  if (IsTopLabelUsed())
    WriteLabelRaw(label);
}

void CWriter::WriteLabelRaw(const LabelDecl& label) {
  Write(label.name, ":", Newline());
  ++label_count_;
}

void CWriter::Write(const GlobalVar& var) {
  assert(var.var.is_name());
  Write(ExternalRef(var.var.name()));
}

void CWriter::Write(const StackVar& sv) {
  Index index = type_stack_.size() - 1 - sv.index;
  Type type = sv.type;
  if (type == Type::Any) {
    assert(index < type_stack_.size());
    type = type_stack_[index];
  }

  StackTypePair stp = {index, type};
  auto iter = stack_var_sym_map_.find(stp);
  if (iter == stack_var_sym_map_.end()) {
    std::string name = MangleType(type) + std::to_string(index);
    Write(DefineStackVarName(index, type, name));
  } else {
    Write(iter->second);
  }
}

void CWriter::Write(Type type) {
  switch (type) {
    case Type::I32: Write("Integer"); break;
    case Type::I64: Write("LongInteger"); break;
    case Type::F32: Write("Float"); break;
    case Type::F64: Write("Double"); break;
    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(TypeEnum type) {
  switch (type.type) {
    case Type::I32: Write("WASM_RT_I32"); break;
    case Type::I64: Write("WASM_RT_I64"); break;
    case Type::F32: Write("WASM_RT_F32"); break;
    case Type::F64: Write("WASM_RT_F64"); break;
    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(SignedType type) {
  switch (type.type) {
    case Type::I32: Write("Integer"); break;
    case Type::I64: Write("LongInteger"); break;
    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(const ResultType& rt) {
  if (rt.types.size() == 1) {
    Write(rt.types[0]);
  } else if (rt.types.size() > 1) {
    Write("Object");
  } else {
    Write("Void");
  }
}

void CWriter::Write(const Const& const_) {
  switch (const_.type()) {
    case Type::I32:
      Writef("%u%%", static_cast<int32_t>(const_.u32()));
      break;

    case Type::I64:
      Writef("%" PRIu64 "&", static_cast<int64_t>(const_.u64()));
      break;

    case Type::F32: {
      uint32_t f32_bits = const_.f32_bits();
      // TODO(binji): Share with similar float info in interp.cc and literal.cc
      if ((f32_bits & 0x7f800000u) == 0x7f800000u) {
        const char* sign = (f32_bits & 0x80000000) ? "-" : "";
        uint32_t significand = f32_bits & 0x7fffffu;
        if (significand == 0) {
          // Infinity.
          Writef("%sFloatInf()", sign);
        } else {
          // Nan.
          Writef("FloatNan()");
        }
      } else if (f32_bits == 0x80000000) {
        // Negative zero. Special-cased so it isn't written as -0 below.
        Writef("-0.0!");
      } else {
        Writef("%.9g!", Bitcast<float>(f32_bits));
      }
      break;
    }

    case Type::F64: {
      uint64_t f64_bits = const_.f64_bits();
      // TODO(binji): Share with similar float info in interp.cc and literal.cc
      if ((f64_bits & 0x7ff0000000000000ull) == 0x7ff0000000000000ull) {
        const char* sign = (f64_bits & 0x8000000000000000ull) ? "-" : "";
        uint64_t significand = f64_bits & 0xfffffffffffffull;
        if (significand == 0) {
          // Infinity.
          Writef("%sDoubleInf()", sign);
        } else {
          // Nan.
          Writef("DoubleNan()");
        }
      } else if (f64_bits == 0x8000000000000000ull) {
        // Negative zero. Special-cased so it isn't written as -0 below.
        Writef("-0.0#");
      } else {
        Writef("%.17g#", Bitcast<double>(f64_bits));
      }
      break;
    }

    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::WriteInitExpr(const ExprList& expr_list) {
  if (expr_list.empty())
    return;

  assert(expr_list.size() == 1);
  const Expr* expr = &expr_list.front();
  switch (expr_list.front().type()) {
    case ExprType::Const:
      Write(cast<ConstExpr>(expr)->const_);
      break;

    case ExprType::GlobalGet:
      Write(GlobalVar(cast<GlobalGetExpr>(expr)->var));
      break;

    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::WriteFuncTypes() {
  Write(Newline());
  Writef("static u32 func_types[%" PRIzd "];", module_->types.size());
  Write(Newline(), Newline());
  Write("static void InitFuncTypes(void) {", Newline());
  Index func_type_index = 0;
  for (TypeEntry* type : module_->types) {
    FuncType* func_type = cast<FuncType>(type);
    Index num_params = func_type->GetNumParams();
    Index num_results = func_type->GetNumResults();
    Write("  func_types[", func_type_index, "] = wasm_rt_register_func_type(",
          num_params, ", ", num_results);
    for (Index i = 0; i < num_params; ++i) {
      Write(", ", TypeEnum(func_type->GetParamType(i)));
    }

    for (Index i = 0; i < num_results; ++i) {
      Write(", ", TypeEnum(func_type->GetResultType(i)));
    }

    Write(")", Newline());
    ++func_type_index;
  }
  Write("}", Newline());
}

void CWriter::WriteImports() {
  if (module_->imports.empty())
    return;

  Write(Newline());

  // TODO(binji): Write imports ordered by type.
  for (const Import* import : module_->imports) {
    const std::string legal_module_name = LegalizeNameNoAddons(import->module_name);
    Write("' import: '", import->module_name, "' '", import->field_name, "'", Newline());
    Write("' ");
    switch (import->kind()) {
      case ExternalKind::Func: {
        const Func& func = cast<FuncImport>(import)->func;
        WriteFuncDeclaration(
            func.decl,
            DefineImportName(
                func.name, import->module_name,
                LegalizeName("", legal_module_name, import->field_name)));
        break;
      }

      case ExternalKind::Global: {
        const Global& global = cast<GlobalImport>(import)->global;
        WriteGlobal(global,
                    DefineImportName(
                        global.name, import->module_name,
                        LegalizeName("m.", legal_module_name, import->field_name)));
        break;
      }

      case ExternalKind::Memory: {
        const Memory& memory = cast<MemoryImport>(import)->memory;
        WriteMemory(DefineImportName(memory.name, import->module_name,
                                     LegalizeName("m.", legal_module_name, import->field_name)));
        break;
      }

      case ExternalKind::Table: {
        const Table& table = cast<TableImport>(import)->table;
        WriteTable(DefineImportName(table.name, import->module_name,
                                    LegalizeName("m.", legal_module_name, import->field_name)));
        break;
      }

      default:
        BRS_UNREACHABLE;
    }

    Write(Newline());
  }
}

void CWriter::WriteFuncDeclarations() {
  if (module_->funcs.size() == module_->num_func_imports)
    return;

  //Write(Newline());

  Index func_index = 0;
  for (const Func* func : module_->funcs) {
    bool is_import = func_index < module_->num_func_imports;
    if (!is_import) {
      DefineGlobalScopeName(func->name);
      //Write("static ");
      //WriteFuncDeclaration(func->decl, DefineGlobalScopeName(func->name));
      //Write(Newline());
    }
    ++func_index;
  }
}

void CWriter::WriteFuncDeclaration(const FuncDeclaration& decl,
                                   const std::string& name) {
  Write("Function ", name, "(");
  for (Index i = 0; i < decl.GetNumParams(); ++i) {
    if (i != 0)
      Write(", ");
    Write("p" + std::to_string(i), " As ", decl.GetParamType(i));
  }
  Write(") As ", ResultType(decl.sig.result_types));
}

void CWriter::WriteGlobals() {
  Index global_index = 0;
  if (module_->globals.size() != module_->num_global_imports) {
    Write(Newline());

    for (const Global* global : module_->globals) {
      bool is_import = global_index < module_->num_global_imports;
      if (!is_import) {
        DefineGlobalScopeName(global->name, "m.");
        Write(Newline());
      }
      ++global_index;
    }
  }

  Write(Newline(), "Function ", options_.name_prefix, "_InitGlobals__()", OpenBrace());
  global_index = 0;
  for (const Global* global : module_->globals) {
    bool is_import = global_index < module_->num_global_imports;
    if (!is_import) {
      assert(!global->init_expr.empty());
      Write(GlobalName(global->name), " = ");
      WriteInitExpr(global->init_expr);
      Write(Newline());
    }
    ++global_index;
  }
  Write(CloseBrace(), "End Function", Newline());
}

void CWriter::WriteGlobal(const Global& global, const std::string& name) {
  Write(global.type, " ", name);
}

void CWriter::WriteMemories() {
  if (module_->memories.size() == module_->num_memory_imports)
    return;

  assert(module_->memories.size() <= 1);
  Index memory_index = 0;
  for (const Memory* memory : module_->memories) {
    bool is_import = memory_index < module_->num_memory_imports;
    if (!is_import) {
      DefineGlobalScopeName(memory->name, "m.");
    }
    ++memory_index;
  }
}

void CWriter::WriteMemory(const std::string& name) {
  Write("Function ", name, " As Object");
}

void CWriter::WriteTables() {
  if (module_->tables.size() == module_->num_table_imports)
    return;

  assert(module_->tables.size() <= 1);
  Index table_index = 0;
  for (const Table* table : module_->tables) {
    bool is_import = table_index < module_->num_table_imports;
    if (!is_import) {
      DefineGlobalScopeName(table->name, "m.");
    }
    ++table_index;
  }
}

void CWriter::WriteTable(const std::string& name) {
  Write("wasm_rt_table_t ", name);
}

void CWriter::WriteDataInitializers() {
  const Memory* memory = module_->memories.empty() ? nullptr : module_->memories[0];

  Write(Newline(), "Function ", options_.name_prefix, "_InitMemory__()", OpenBrace());
  if (memory && module_->num_memory_imports == 0) {
    uint32_t max =
        memory->page_limits.has_max ? memory->page_limits.max : 65536;
    Write(ExternalPtr(memory->name), " = CreateObject(\"roByteArray\")", Newline());
    Write(ExternalPtr(memory->name), "[", memory->page_limits.initial * WABT_PAGE_SIZE, "] = 0", Newline());
    Write(ExternalPtr(memory->name), "Max = ", max, Newline());
  }

  Index data_segment_index = 0;
  for (const DataSegment* data_segment : module_->data_segments) {
    const std::string data_segment_name = "data_segment_" + std::to_string(data_segment_index);
    Write(data_segment_name, " = CreateObject(\"roByteArray\")", Newline());
    Write(data_segment_name, ".FromHexString(\"");
    for (uint8_t x : data_segment->data) {
      Writef("%02x", x);
    }
    Write("\")", Newline());

    Write("MemoryCopy(", ExternalRef(memory->name), ", ");
    WriteInitExpr(data_segment->offset);
    Write(", ", data_segment_name, ", 0, ", data_segment->data.size(), ")", Newline());
    ++data_segment_index;
  }

  Write(CloseBrace(), "End Function", Newline());
}

void CWriter::WriteElemInitializers() {
  const Table* table = module_->tables.empty() ? nullptr : module_->tables[0];

  Write(Newline(), "Function ", options_.name_prefix, "_InitTable__()", OpenBrace());
  if (table && module_->num_table_imports == 0) {
    uint32_t max =
        table->elem_limits.has_max ? table->elem_limits.max : UINT32_MAX;
    Write(ExternalPtr(table->name), " = []", Newline());
  }
  for (const ElemSegment* elem_segment : module_->elem_segments) {
    Write("offset = ");
    WriteInitExpr(elem_segment->offset);
    Write(Newline());

    size_t i = 0;
    for (const ElemExpr& elem_expr : elem_segment->elem_exprs) {
      // We don't support the bulk-memory proposal here, so we know that we
      // don't have any passive segments (where ref.null can be used).
      assert(elem_expr.kind == ElemExprKind::RefFunc);
      const Func* func = module_->GetFunc(elem_expr.var);
      Index func_type_index = module_->GetFuncTypeIndex(func->decl.type_var);

      Write(ExternalRef(table->name), "[offset + ", i, "] = ", ExternalPtr(func->name), Newline());
      ++i;
    }
  }

  Write(CloseBrace(), "End Function", Newline());
}

void CWriter::WriteInitExports() {
  Write(Newline(), "Function ", options_.name_prefix, "_InitExports__()", OpenBrace());
  WriteExports();
  Write(CloseBrace(), "End Function", Newline());

  // Here we only export functions since they are global and not done with m.something
  for (const Export* export_ : module_->exports) {
    if (export_->kind != ExternalKind::Func) {
      continue;
    }
    const Func* func = module_->GetFunc(export_->var);
    const std::string mangled_name = LegalizeName("", options_.name_prefix, export_->name);

    // If the name is the same as the export, don't bother wrapping it
    if (mangled_name == GetGlobalName(func->name)) {
      continue;
    }

    Write("' export: '", options_.name_prefix, "' '", module_->name, "' '", export_->name, "'", Newline());
    Write("Function ", mangled_name, "(");
    for (Index i = 0; i < func->GetNumParams(); ++i) {
      if (i != 0) {
        Write(", ");
      }
      Write("p", i, " As ", func->GetParamType(i));
    }
    Write(")", OpenBrace());

    Write("Return ", ExternalPtr(func->name), "(");
    for (Index i = 0; i < func->GetNumParams(); ++i) {
      if (i != 0) {
        Write(", ");
      }
      Write("p", i);
    }
    Write(")", Newline());

    Write(CloseBrace(), "End Function", Newline());
  }
}

void CWriter::WriteExports() {
  for (const Export* export_ : module_->exports) {
    if (export_->kind == ExternalKind::Func) {
      continue;
    }

    Write("' export: '", options_.name_prefix, "' '", module_->name, "' '", export_->name, "'", Newline());
    const std::string mangled_name = LegalizeName("m.", options_.name_prefix, export_->name);
    std::string internal_name;

    switch (export_->kind) {
      case ExternalKind::Global: {
        const Global* global = module_->GetGlobal(export_->var);
        internal_name = global->name;
        break;
      }

      case ExternalKind::Memory: {
        const Memory* memory = module_->GetMemory(export_->var);
        internal_name = memory->name;
        break;
      }

      case ExternalKind::Table: {
        const Table* table = module_->GetTable(export_->var);
        internal_name = table->name;
        break;
      }

      default:
        BRS_UNREACHABLE;
    }

    Write(mangled_name, " = ", ExternalPtr(internal_name), Newline());
  }
}

void CWriter::WriteInit() {
  Write(Newline(), "Function ", options_.name_prefix, "Init__()", OpenBrace());
  //Write("InitFuncTypes()", Newline());
  Write(options_.name_prefix, "_InitGlobals__()", Newline());
  Write(options_.name_prefix, "_InitMemory__()", Newline());
  Write(options_.name_prefix, "_InitTable__()", Newline());
  Write(options_.name_prefix, "_InitExports__()", Newline());
  for (Var* var : module_->starts) {
    Write(ExternalRef(module_->GetFunc(*var)->name), "()", Newline());
  }
  Write(CloseBrace(), "End Function", Newline());
}

void CWriter::WriteFuncs() {
  Index func_index = 0;
  for (const Func* func : module_->funcs) {
    bool is_import = func_index < module_->num_func_imports;
    if (!is_import) {
      DefineGlobalScopeName(func->name);
      Write(Newline(), *func, Newline());
    }
    ++func_index;
  }
}

void CWriter::Write(const Func& func) {
  func_ = &func;
  label_count_ = 0;
  // Copy symbols from global symbol table so we don't shadow them.
  local_syms_ = global_syms_;
  local_sym_map_.clear();
  stack_var_sym_map_.clear();

  Write("Function ", GlobalName(func.name), "(");

  std::vector<std::string> index_to_name;
  MakeTypeBindingReverseMapping(func_->GetNumParamsAndLocals(), func_->bindings,
                                &index_to_name);
  WriteParams(index_to_name);

  Write(") As ", ResultType(func.decl.sig.result_types), OpenBrace());

  WriteLocals(index_to_name);

  stream_ = &func_stream_;
  stream_->ClearOffset();

  std::string label = DefineLocalScopeName(kImplicitFuncLabel);
  ResetTypeStack(0);
  std::string empty;  // Must not be temporary, since address is taken by Label.
  PushLabel(LabelType::Func, empty, func.decl.sig);
  Write(func.exprs, LabelDecl(label));
  PopLabel();
  ResetTypeStack(0);
  PushTypes(func.decl.sig.result_types);

  size_t results = func.decl.sig.result_types.size();
  if (results != 0) {
    // Return the top of the stack implicitly.
    if (results == 1) {
      Write("Return ", StackVar(0), Newline());
    } else {
      Write("Return [");
      for (int i = (int)results - 1; i >= 0; --i) {
        Write(StackVar(i));
        if (i != 0) {
          Write(", ");
        }
      }
      Write("]", Newline());
    }
  }

  stream_ = brs_stream_;

  //WriteStackVarDeclarations();

  std::unique_ptr<OutputBuffer> buf = func_stream_.ReleaseOutputBuffer();
  stream_->WriteData(buf->data.data(), buf->data.size());

  Write(CloseBrace(), "End Function", Newline());

  func_stream_.Clear();
  func_ = nullptr;

  const size_t label_limit = 128;
  if (label_count_ > label_limit) {
    std::cerr << "Function " << func.name << " had " << label_count_ << " labels (*suggested* max " << label_limit << " due to BrightScript, hard limit is 256)" << std::endl;
  }
  label_count_ = 0;
  const size_t variable_limit = 254;
  const size_t variable_count = func.GetNumParamsAndLocals() + stack_var_sym_map_.size();
  if (variable_count > 254) {
    std::cerr << "Function " << func.name << " had " << variable_count << " variables (max " << variable_limit << " due to BrightScript)" << std::endl;
  }
}

void CWriter::WriteParams(const std::vector<std::string>& index_to_name) {
  Indent(4);
  for (Index i = 0; i < func_->GetNumParams(); ++i) {
    if (i != 0) {
      Write(", ");
    }
    Write(DefineLocalScopeName(index_to_name[i]), " As ", func_->GetParamType(i));
  }
  Dedent(4);
}

void CWriter::WriteLocals(const std::vector<std::string>& index_to_name) {
  Index num_params = func_->GetNumParams();
  for (Type type : {Type::I32, Type::I64, Type::F32, Type::F64}) {
    Index local_index = 0;
    size_t count = 0;
    for (Type local_type : func_->local_types) {
      if (local_type == type) {
        Write(DefineLocalScopeName(index_to_name[num_params + local_index]),
              " = 0", Newline());
        ++count;
      }
      ++local_index;
    }
    if (count != 0) {
      Write(Newline());
    }
  }
}

void CWriter::WriteStackVarDeclarations() {
  for (Type type : {Type::I32, Type::I64, Type::F32, Type::F64}) {
    size_t count = 0;
    for (const auto& pair : stack_var_sym_map_) {
      Type stp_type = pair.first.second;
      const std::string& name = pair.second;

      if (stp_type == type) {
        if (count == 0) {
          Write(type, " ");
          Indent(4);
        } else {
          Write(", ");
          if ((count % 8) == 0)
            Write(Newline());
        }

        Write(name);
        ++count;
      }
    }
    if (count != 0) {
      Dedent(4);
      Write(Newline());
    }
  }
}

void CWriter::Write(const ExprList& exprs) {
  for (const Expr& expr : exprs) {
    switch (expr.type()) {
      case ExprType::Binary:
        Write(*cast<BinaryExpr>(&expr));
        break;

      case ExprType::Block: {
        const Block& block = cast<BlockExpr>(&expr)->block;
        std::string label = DefineLocalScopeName(block.label);
        size_t mark = MarkTypeStack();
        PushLabel(LabelType::Block, block.label, block.decl.sig);
        Write(block.exprs, LabelDecl(label));
        ResetTypeStack(mark);
        PopLabel();
        PushTypes(block.decl.sig.result_types);
        break;
      }

      case ExprType::Br:
        Write(GotoLabel(cast<BrExpr>(&expr)->var), Newline());
        // Stop processing this ExprList, since the following are unreachable.
        return;

      case ExprType::BrIf:
        Write("If ", StackVar(0), " Then", OpenBrace());
        DropTypes(1);
        Write(GotoLabel(cast<BrIfExpr>(&expr)->var), Newline(), CloseBrace(), "End If", Newline());
        break;

      case ExprType::BrTable: {
        const auto* bt_expr = cast<BrTableExpr>(&expr);
        // Reduce the number of If blocks (Brightscript limit) by using range checks
        // e.g. If switch >= 1 And switch <= 10 Or switch = 15 Then
        // Also better for performance
        // Note that we now don't use Else because we found it causes the issue with BrightScript limits
        typedef std::pair<Index, Index> IndexRange;
        std::unordered_map<Var, std::vector<IndexRange>, VarHasher, VarEqual> labels_to_indices;
        for (Index i = 0; i < bt_expr->targets.size(); ++i) {
          const Var& var = bt_expr->targets[i];
          // Ignore labels with the same name as the default target (default will fall through to this anyways)
          if (VarEqual()(var, bt_expr->default_target)) {
            continue;
          }
          auto& indices = labels_to_indices[var];
          if (indices.size() > 0) {
            auto& last = indices.back();
            if (i == last.second + 1) {
              last.second = i;
            } else {
              indices.push_back(IndexRange(i, i));
            }
          } else {
            indices.push_back(IndexRange(i, i));
          }
        }
        
        // If we only have a default target, then just jump to it.
        if (labels_to_indices.empty()) {
          DropTypes(1);
          Write(GotoLabel(bt_expr->default_target), Newline());
        } else {
          Write("switch = ", StackVar(0), Newline());
          DropTypes(1);
          for (const auto& pair : labels_to_indices) {
            Write("If ");

            auto& indices = pair.second;
            Index prev = -1;
            bool wrote_first_compare = false;
            for (auto& range : indices) {
              if (wrote_first_compare) {
                Write(" Or ");
              }
              if (range.first == range.second) {
                Write("switch = ", range.first);
              } else {
                Write("switch >= ", range.first, " And switch <= ", range.second);
              }
              wrote_first_compare = true;
            }
            Write(" Then", OpenBrace());
            Write(GotoLabel(pair.first), Newline());
            Write("End If", CloseBrace(), Newline());
          }
          Write(GotoLabel(bt_expr->default_target), Newline());
        }
        // Stop processing this ExprList, since the following are unreachable.
        return;
      }

      case ExprType::Call: {
        const Var& var = cast<CallExpr>(&expr)->var;
        const Func& func = *module_->GetFunc(var);
        Index num_params = func.GetNumParams();
        Index num_results = func.GetNumResults();
        assert(type_stack_.size() >= num_params);
        if (num_results > 0) {
          if (num_results == 1) {
            Write(StackVar(num_params - 1, func.GetResultType(0)));
          } else {
            Write("multi");
          }
          Write(" = ");
        }

        Write(GlobalVar(var), "(");
        for (Index i = 0; i < num_params; ++i) {
          if (i != 0) {
            Write(", ");
          }
          Write(StackVar(num_params - i - 1));
        }
        Write(")", Newline());
        DropTypes(num_params);
        PushTypes(func.decl.sig.result_types);
        if (num_results > 1) {
          for (Index i = 0; i < num_results; ++i) {
            Write(StackVar(num_results - i - 1, func.GetResultType(i)), " = multi[", i, "]", Newline());
          }
        }
        break;
      }

      case ExprType::CallIndirect: {
        const FuncDeclaration& decl = cast<CallIndirectExpr>(&expr)->decl;
        Index num_params = decl.GetNumParams();
        Index num_results = decl.GetNumResults();
        assert(type_stack_.size() > num_params);
        if (num_results > 0) {
          if (num_results == 1) {
            Write(StackVar(num_params, decl.GetResultType(0)));
          } else {
            Write("multi");
          }
          Write(" = ");
        }

        assert(module_->tables.size() == 1);
        const Table* table = module_->tables[0];

        assert(decl.has_func_type);
        Index func_type_index = module_->GetFuncTypeIndex(decl.type_var);

        Write(ExternalRef(table->name), "[", StackVar(0), "](");
        for (Index i = 0; i < num_params; ++i) {
          if (i != 0) {
            Write(", ");
          }
          Write(StackVar(num_params - i));
        }
        Write(")", Newline());
        DropTypes(num_params + 1);
        PushTypes(decl.sig.result_types);
        if (num_results > 1) {
          for (Index i = 0; i < num_results; ++i) {
            Write(StackVar(num_results - i - 1), " = multi[", i, "]", Newline());
          }
        }
        break;
      }

      case ExprType::Compare:
        Write(*cast<CompareExpr>(&expr));
        break;

      case ExprType::Const: {
        const Const& const_ = cast<ConstExpr>(&expr)->const_;
        PushType(const_.type());
        Write(StackVar(0), " = ", const_, Newline());
        break;
      }

      case ExprType::Convert:
        Write(*cast<ConvertExpr>(&expr));
        break;

      case ExprType::Drop:
        DropTypes(1);
        break;

      case ExprType::GlobalGet: {
        const Var& var = cast<GlobalGetExpr>(&expr)->var;
        PushType(module_->GetGlobal(var)->type);
        Write(StackVar(0), " = ", GlobalVar(var), Newline());
        break;
      }

      case ExprType::GlobalSet: {
        const Var& var = cast<GlobalSetExpr>(&expr)->var;
        Write(GlobalVar(var), " = ", StackVar(0), Newline());
        DropTypes(1);
        break;
      }

      case ExprType::If: {
        const IfExpr& if_ = *cast<IfExpr>(&expr);
        Write("If ", StackVar(0), " Then", OpenBrace());
        DropTypes(1);
        std::string label = DefineLocalScopeName(if_.true_.label);
        size_t mark = MarkTypeStack();
        PushLabel(LabelType::If, if_.true_.label, if_.true_.decl.sig);
        Write(if_.true_.exprs, CloseBrace());
        if (!if_.false_.empty()) {
          ResetTypeStack(mark);
          Write("Else", OpenBrace(), if_.false_, CloseBrace());
        }
        ResetTypeStack(mark);
        Write("End If", Newline(), LabelDecl(label));
        PopLabel();
        PushTypes(if_.true_.decl.sig.result_types);
        break;
      }

      case ExprType::Load:
        Write(*cast<LoadExpr>(&expr));
        break;

      case ExprType::LocalGet: {
        const Var& var = cast<LocalGetExpr>(&expr)->var;
        PushType(func_->GetLocalType(var));
        Write(StackVar(0), " = ", var, Newline());
        break;
      }

      case ExprType::LocalSet: {
        const Var& var = cast<LocalSetExpr>(&expr)->var;
        Write(var, " = ", StackVar(0), Newline());
        DropTypes(1);
        break;
      }

      case ExprType::LocalTee: {
        const Var& var = cast<LocalTeeExpr>(&expr)->var;
        Write(var, " = ", StackVar(0), Newline());
        break;
      }

      case ExprType::Loop: {
        const Block& block = cast<LoopExpr>(&expr)->block;
        if (!block.exprs.empty()) {
          WriteLabelRaw(LabelDecl(DefineLocalScopeName(block.label)));
          Indent();
          size_t mark = MarkTypeStack();
          PushLabel(LabelType::Loop, block.label, block.decl.sig);
          Write(Newline(), block.exprs);
          ResetTypeStack(mark);
          PopLabel();
          PushTypes(block.decl.sig.result_types);
          Dedent();
        }
        break;
      }

      case ExprType::AtomicLoad:
      case ExprType::AtomicRmw:
      case ExprType::AtomicRmwCmpxchg:
      case ExprType::AtomicStore:
      case ExprType::AtomicWait:
      case ExprType::AtomicFence:
      case ExprType::AtomicNotify:
      case ExprType::BrOnExn:
      case ExprType::Rethrow:
      case ExprType::ReturnCall:
      case ExprType::ReturnCallIndirect:
      case ExprType::Throw:
      case ExprType::Try:
      case ExprType::MemoryCopy:
      case ExprType::DataDrop:
      case ExprType::MemoryInit:
      case ExprType::MemoryFill:
      case ExprType::TableCopy:
      case ExprType::ElemDrop:
      case ExprType::TableInit:
      case ExprType::TableGet:
      case ExprType::TableSet:
      case ExprType::TableGrow:
      case ExprType::TableSize:
      case ExprType::TableFill:
      case ExprType::RefFunc:
      case ExprType::RefNull:
      case ExprType::RefIsNull:
        BRS_ABORT("Unsupported expression " << GetExprTypeName(expr.type()));
        break;

      case ExprType::MemoryGrow: {
        assert(module_->memories.size() == 1);
        Memory* memory = module_->memories[0];

        Write(StackVar(0), " = MemoryGrow(", ExternalPtr(memory->name), ", ", ExternalPtr(memory->name), "Max, ", StackVar(0), ")", Newline());
        break;
      }

      case ExprType::MemorySize: {
        assert(module_->memories.size() == 1);
        Memory* memory = module_->memories[0];

        PushType(Type::I32);
        Write(StackVar(0), " = MemorySize(", ExternalRef(memory->name), ")", Newline());
        break;
      }

      case ExprType::Nop:
        break;

      case ExprType::Return:
        // Goto the function label instead; this way we can do shared function
        // cleanup code in one place.
        Write(GotoLabel(Var(label_stack_.size() - 1)), Newline());
        // Stop processing this ExprList, since the following are unreachable.
        return;

      case ExprType::Select: {
        Type type = StackType(1);
        Write("If ", StackVar(0), " = 0 Then", OpenBrace());
        Write(StackVar(2), " = ", StackVar(1), Newline());
        Write(CloseBrace(), "End If", Newline());
        //Write(StackVar(2), " = ", StackVar(0), " ? ", StackVar(2), " : ",
        //      StackVar(1), Newline());
        DropTypes(3);
        PushType(type);
        break;
      }

      case ExprType::Store:
        Write(*cast<StoreExpr>(&expr));
        break;

      case ExprType::Unary:
        Write(*cast<UnaryExpr>(&expr));
        break;

      case ExprType::Ternary:
        Write(*cast<TernaryExpr>(&expr));
        break;

      case ExprType::SimdLaneOp: {
        Write(*cast<SimdLaneOpExpr>(&expr));
        break;
      }

      case ExprType::SimdShuffleOp: {
        Write(*cast<SimdShuffleOpExpr>(&expr));
        break;
      }

      case ExprType::LoadSplat:
        Write(*cast<LoadSplatExpr>(&expr));
        break;

      case ExprType::Unreachable:
        Write("Stop 'Unreachable", Newline());
        return;
    }
  }
}

void CWriter::WriteSimpleUnaryExpr(Opcode opcode, const char* op) {
  Type result_type = opcode.GetResultType();
  Write(StackVar(0, result_type), " = ", op, "(", StackVar(0), ")", Newline());
  DropTypes(1);
  PushType(opcode.GetResultType());
}

void CWriter::WriteInfixBinaryExpr(Opcode opcode,
                                   const char* op,
                                   AssignOp assign_op) {
  Type result_type = opcode.GetResultType();
  Write(StackVar(1, result_type));
  //if (assign_op == AssignOp::Allowed) {
  //  Write(" ", op, "= ", StackVar(0));
  //} else {
    Write(" = ", StackVar(1), " ", op, " ", StackVar(0));
  //}
  Write(Newline());
  DropTypes(2);
  PushType(result_type);
}

void CWriter::WritePrefixBinaryExpr(Opcode opcode, const char* op) {
  Type result_type = opcode.GetResultType();
  Write(StackVar(1, result_type), " = ", op, "(", StackVar(1), ", ",
        StackVar(0), ")", Newline());
  DropTypes(2);
  PushType(result_type);
}

void CWriter::WriteSignedBinaryExpr(Opcode opcode, const char* op) {
  Type result_type = opcode.GetResultType();
  Type type = opcode.GetParamType1();
  assert(opcode.GetParamType2() == type);
  // TODO(trevor): This is WRONG but we need to move on (removed casting)
  Write(StackVar(1, result_type), " = (", StackVar(1), " ", op, " ", StackVar(0), ")", Newline());
  //Write(StackVar(1, result_type), " = (", type, ")((", SignedType(type), ")",
  //      StackVar(1), " ", op, " (", SignedType(type), ")", StackVar(0), ")",
  //      Newline());
  DropTypes(2);
  PushType(result_type);
}

void CWriter::Write(const BinaryExpr& expr) {
  switch (expr.opcode) {
    case Opcode::I32Add:
    case Opcode::I64Add:
    case Opcode::F32Add:
    case Opcode::F64Add:
      WriteInfixBinaryExpr(expr.opcode, "+");
      break;

    case Opcode::I32Sub:
    case Opcode::I64Sub:
    case Opcode::F32Sub:
    case Opcode::F64Sub:
      WriteInfixBinaryExpr(expr.opcode, "-");
      break;

    case Opcode::I32Mul:
    case Opcode::I64Mul:
    case Opcode::F32Mul:
    case Opcode::F64Mul:
      WriteInfixBinaryExpr(expr.opcode, "*");
      break;

    case Opcode::I32DivS:
      WriteInfixBinaryExpr(expr.opcode, "\\");
      break;

    case Opcode::I64DivS:
      WriteInfixBinaryExpr(expr.opcode, "\\");
      break;

    case Opcode::I32DivU:
      WritePrefixBinaryExpr(expr.opcode, "I32DivU");
      break;

    case Opcode::I64DivU:
      WritePrefixBinaryExpr(expr.opcode, "I64DivU");
      break;

    case Opcode::F32Div:
      WritePrefixBinaryExpr(expr.opcode, "F32Div");
      break;

    case Opcode::F64Div:
      WritePrefixBinaryExpr(expr.opcode, "F64Div");
      break;

    case Opcode::I32RemS:
      WriteInfixBinaryExpr(expr.opcode, "MOD");
      break;

    case Opcode::I64RemS:
      WriteInfixBinaryExpr(expr.opcode, "MOD");
      break;

    case Opcode::I32RemU:
      WritePrefixBinaryExpr(expr.opcode, "I32RemU");
      break;

    case Opcode::I64RemU:
      WritePrefixBinaryExpr(expr.opcode, "I64RemU");
      break;

    case Opcode::I32And:
    case Opcode::I64And:
      WriteInfixBinaryExpr(expr.opcode, "AND");
      break;

    case Opcode::I32Or:
    case Opcode::I64Or:
      WriteInfixBinaryExpr(expr.opcode, "OR");
      break;

    case Opcode::I32Xor:
      WritePrefixBinaryExpr(expr.opcode, "I32Xor");
      break;

    case Opcode::I64Xor:
      WritePrefixBinaryExpr(expr.opcode, "I64Xor");
      break;

    case Opcode::I32Shl:
    case Opcode::I64Shl:
      Write(StackVar(1), " <<= (", StackVar(0), " AND ",
            GetShiftMask(expr.opcode.GetResultType()), ")", Newline());
      DropTypes(1);
      break;

    case Opcode::I32ShrS:
      WritePrefixBinaryExpr(expr.opcode, "I32ShrS");
      break;

    case Opcode::I64ShrS:
      WritePrefixBinaryExpr(expr.opcode, "I64ShrS");
      break;

    case Opcode::I32ShrU:
    case Opcode::I64ShrU:
      Write(StackVar(1), " >>= (", StackVar(0), " AND ",
            GetShiftMask(expr.opcode.GetResultType()), ")", Newline());
      DropTypes(1);
      break;

    case Opcode::I32Rotl:
      WritePrefixBinaryExpr(expr.opcode, "I32Rotl");
      break;

    case Opcode::I64Rotl:
      WritePrefixBinaryExpr(expr.opcode, "I64Rotl");
      break;

    case Opcode::I32Rotr:
      WritePrefixBinaryExpr(expr.opcode, "I32Rotr");
      break;

    case Opcode::I64Rotr:
      WritePrefixBinaryExpr(expr.opcode, "I64Rotr");
      break;

    case Opcode::F32Min:
      WritePrefixBinaryExpr(expr.opcode, "F32Min");
      break;

    case Opcode::F64Min:
      WritePrefixBinaryExpr(expr.opcode, "F64Min");
      break;

    case Opcode::F32Max:
      WritePrefixBinaryExpr(expr.opcode, "F32Max");
      break;

    case Opcode::F64Max:
      WritePrefixBinaryExpr(expr.opcode, "F64Max");
      break;

    case Opcode::F32Copysign:
      WritePrefixBinaryExpr(expr.opcode, "F32Copysign");
      break;

    case Opcode::F64Copysign:
      WritePrefixBinaryExpr(expr.opcode, "F64Copysign");
      break;

    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(const CompareExpr& expr) {
  switch (expr.opcode) {
    case Opcode::I32Eq:
      WritePrefixBinaryExpr(expr.opcode, "I32Eq");
      break;
    case Opcode::I64Eq:
      WritePrefixBinaryExpr(expr.opcode, "I64Eq");
      break;
    case Opcode::F32Eq:
      WritePrefixBinaryExpr(expr.opcode, "F32Eq");
      break;
    case Opcode::F64Eq:
      WritePrefixBinaryExpr(expr.opcode, "F64Eq");
      break;
    case Opcode::I32Ne:
      WritePrefixBinaryExpr(expr.opcode, "I32Ne");
      break;
    case Opcode::I64Ne:
      WritePrefixBinaryExpr(expr.opcode, "I64Ne");
      break;
    case Opcode::F32Ne:
      WritePrefixBinaryExpr(expr.opcode, "F32Ne");
      break;
    case Opcode::F64Ne:
      WritePrefixBinaryExpr(expr.opcode, "F64Ne");
      break;
    case Opcode::I32LtS:
      WritePrefixBinaryExpr(expr.opcode, "I32LtS");
      break;
    case Opcode::I64LtS:
      WritePrefixBinaryExpr(expr.opcode, "I64LtS");
      break;
    case Opcode::I32LtU:
      WritePrefixBinaryExpr(expr.opcode, "I32LtU");
      break;
    case Opcode::I64LtU:
      WritePrefixBinaryExpr(expr.opcode, "I64LtU");
      break;
    case Opcode::F32Lt:
      WritePrefixBinaryExpr(expr.opcode, "F32Lt");
      break;
    case Opcode::F64Lt:
      WritePrefixBinaryExpr(expr.opcode, "F64Lt");
      break;
    case Opcode::I32LeS:
      WritePrefixBinaryExpr(expr.opcode, "I32LeS");
      break;
    case Opcode::I64LeS:
      WritePrefixBinaryExpr(expr.opcode, "I64LeS");
      break;
    case Opcode::I32LeU:
      WritePrefixBinaryExpr(expr.opcode, "I32LeU");
      break;
    case Opcode::I64LeU:
      WritePrefixBinaryExpr(expr.opcode, "I64LeU");
      break;
    case Opcode::F32Le:
      WritePrefixBinaryExpr(expr.opcode, "F32Le");
      break;
    case Opcode::F64Le:
      WritePrefixBinaryExpr(expr.opcode, "F64Le");
      break;
    case Opcode::I32GtS:
      WritePrefixBinaryExpr(expr.opcode, "I32GtS");
      break;
    case Opcode::I64GtS:
      WritePrefixBinaryExpr(expr.opcode, "I64GtS");
      break;
    case Opcode::I32GtU:
      WritePrefixBinaryExpr(expr.opcode, "I32GtU");
      break;
    case Opcode::I64GtU:
      WritePrefixBinaryExpr(expr.opcode, "I64GtU");
      break;
    case Opcode::F32Gt:
      WritePrefixBinaryExpr(expr.opcode, "F32Gt");
      break;
    case Opcode::F64Gt:
      WritePrefixBinaryExpr(expr.opcode, "F64Gt");
      break;
    case Opcode::I32GeS:
      WritePrefixBinaryExpr(expr.opcode, "I32GeS");
      break;
    case Opcode::I64GeS:
      WritePrefixBinaryExpr(expr.opcode, "I64GeS");
      break;
    case Opcode::I32GeU:
      WritePrefixBinaryExpr(expr.opcode, "I32GeU");
      break;
    case Opcode::I64GeU:
      WritePrefixBinaryExpr(expr.opcode, "I64GeU");
      break;
    case Opcode::F32Ge:
      WritePrefixBinaryExpr(expr.opcode, "F32Ge");
      break;
    case Opcode::F64Ge:
      WritePrefixBinaryExpr(expr.opcode, "F64Ge");
      break;

    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(const ConvertExpr& expr) {
  switch (expr.opcode) {
    case Opcode::I32Eqz:
      WriteSimpleUnaryExpr(expr.opcode, "I32Eqz");
      break;
    case Opcode::I64Eqz:
      WriteSimpleUnaryExpr(expr.opcode, "I64Eqz");
      break;

    case Opcode::I64ExtendI32S:
      WriteSimpleUnaryExpr(expr.opcode, "I64ExtendI32S");
      break;

    case Opcode::I64ExtendI32U:
      WriteSimpleUnaryExpr(expr.opcode, "I64ExtendI32U");
      break;

    case Opcode::I32WrapI64:
      WriteSimpleUnaryExpr(expr.opcode, "I32WrapI64");
      break;

    case Opcode::I32TruncF32S:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncF32S");
      break;

    case Opcode::I64TruncF32S:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncF32S");
      break;

    case Opcode::I32TruncF64S:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncF64S");
      break;

    case Opcode::I64TruncF64S:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncF64S");
      break;

    case Opcode::I32TruncF32U:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncF32U");
      break;

    case Opcode::I64TruncF32U:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncF32U");
      break;

    case Opcode::I32TruncF64U:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncF64U");
      break;

    case Opcode::I64TruncF64U:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncF64U");
      break;

    case Opcode::I32TruncSatF32S:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncSatF32S");
      break;

    case Opcode::I64TruncSatF32S:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncSatF32S");
      break;

    case Opcode::I32TruncSatF64S:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncSatF64S");
      break;

    case Opcode::I64TruncSatF64S:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncSatF64S");
      break;

    case Opcode::I32TruncSatF32U:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncSatF32U");
      break;

    case Opcode::I64TruncSatF32U:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncSatF32U");
      break;

    case Opcode::I32TruncSatF64U:
      WriteSimpleUnaryExpr(expr.opcode, "I32TruncSatF64U");
      break;

    case Opcode::I64TruncSatF64U:
      WriteSimpleUnaryExpr(expr.opcode, "I64TruncSatF64U");
      break;

    case Opcode::F32ConvertI32S:
      WriteSimpleUnaryExpr(expr.opcode, "F32ConvertI32S");
      break;

    case Opcode::F32ConvertI64S:
      WriteSimpleUnaryExpr(expr.opcode, "F32ConvertI64S");
      break;

    case Opcode::F32ConvertI32U:
      WriteSimpleUnaryExpr(expr.opcode, "F32ConvertI32U");
      break;

    case Opcode::F32DemoteF64:
      WriteSimpleUnaryExpr(expr.opcode, "F32DemoteF64");
      break;

    case Opcode::F32ConvertI64U:
      WriteSimpleUnaryExpr(expr.opcode, "F32ConvertI64U");
      break;

    case Opcode::F64ConvertI32S:
      WriteSimpleUnaryExpr(expr.opcode, "F64ConvertI32S");
      break;

    case Opcode::F64ConvertI64S:
      WriteSimpleUnaryExpr(expr.opcode, "F64ConvertI64S");
      break;

    case Opcode::F64ConvertI32U:
      WriteSimpleUnaryExpr(expr.opcode, "F64ConvertI32U");
      break;

    case Opcode::F64PromoteF32:
      WriteSimpleUnaryExpr(expr.opcode, "F64PromoteF32");
      break;

    case Opcode::F64ConvertI64U:
      WriteSimpleUnaryExpr(expr.opcode, "F64ConvertI64U");
      break;

    case Opcode::F32ReinterpretI32:
      WriteSimpleUnaryExpr(expr.opcode, "F32ReinterpretI32");
      break;

    case Opcode::I32ReinterpretF32:
      WriteSimpleUnaryExpr(expr.opcode, "I32ReinterpretF32");
      break;

    case Opcode::F64ReinterpretI64:
      WriteSimpleUnaryExpr(expr.opcode, "F64ReinterpretI64");
      break;

    case Opcode::I64ReinterpretF64:
      WriteSimpleUnaryExpr(expr.opcode, "I64ReinterpretF64");
      break;

    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(const LoadExpr& expr) {
  const char* func = nullptr;
  switch (expr.opcode) {
    case Opcode::I32Load: func = "I32Load"; break;
    case Opcode::I64Load: func = "I64Load"; break;
    case Opcode::F32Load: func = "F32Load"; break;
    case Opcode::F64Load: func = "F64Load"; break;
    case Opcode::I32Load8S: func = "I32Load8S"; break;
    case Opcode::I64Load8S: func = "I64Load8S"; break;
    case Opcode::I32Load8U: func = "I32Load8U"; break;
    case Opcode::I64Load8U: func = "I64Load8U"; break;
    case Opcode::I32Load16S: func = "I32Load16S"; break;
    case Opcode::I64Load16S: func = "I64Load16S"; break;
    case Opcode::I32Load16U: func = "I32Load16U"; break;
    case Opcode::I64Load16U: func = "I64Load16U"; break;
    case Opcode::I64Load32S: func = "I64Load32S"; break;
    case Opcode::I64Load32U: func = "I64Load32U"; break;

    default:
      BRS_UNREACHABLE;
  }

  assert(module_->memories.size() == 1);
  Memory* memory = module_->memories[0];

  Type result_type = expr.opcode.GetResultType();
  Write(StackVar(0, result_type), " = ", func, "(", ExternalPtr(memory->name), ", ", StackVar(0));
  if (expr.offset != 0)
    Write(" + ", expr.offset);
  Write(")", Newline());
  DropTypes(1);
  PushType(result_type);
}

void CWriter::Write(const StoreExpr& expr) {
  const char* func = nullptr;
  switch (expr.opcode) {
    case Opcode::I32Store: func = "I32Store"; break;
    case Opcode::I64Store: func = "I64Store"; break;
    case Opcode::F32Store: func = "F32Store"; break;
    case Opcode::F64Store: func = "F64Store"; break;
    case Opcode::I32Store8: func = "I32Store8"; break;
    case Opcode::I64Store8: func = "I64Store8"; break;
    case Opcode::I32Store16: func = "I32Store16"; break;
    case Opcode::I64Store16: func = "I64Store16"; break;
    case Opcode::I64Store32: func = "I64Store32"; break;

    default:
      BRS_UNREACHABLE;
  }

  assert(module_->memories.size() == 1);
  Memory* memory = module_->memories[0];

  Write(func, "(", ExternalPtr(memory->name), ", ", StackVar(1));
  if (expr.offset != 0)
    Write(" + ", expr.offset);
  Write(", ", StackVar(0), ")", Newline());
  DropTypes(2);
}

void CWriter::Write(const UnaryExpr& expr) {
  switch (expr.opcode) {
    case Opcode::I32Clz:
      WriteSimpleUnaryExpr(expr.opcode, "I32Clz");
      break;

    case Opcode::I64Clz:
      WriteSimpleUnaryExpr(expr.opcode, "I64Clz");
      break;

    case Opcode::I32Ctz:
      WriteSimpleUnaryExpr(expr.opcode, "I32Ctz");
      break;

    case Opcode::I64Ctz:
      WriteSimpleUnaryExpr(expr.opcode, "I64Ctz");
      break;

    case Opcode::I32Popcnt:
      WriteSimpleUnaryExpr(expr.opcode, "I32Popcnt");
      break;

    case Opcode::I64Popcnt:
      WriteSimpleUnaryExpr(expr.opcode, "I64Popcnt");
      break;

    case Opcode::F32Neg:
    case Opcode::F64Neg:
      WriteSimpleUnaryExpr(expr.opcode, "-");
      break;

    case Opcode::F32Abs:
      WriteSimpleUnaryExpr(expr.opcode, "Abs");
      break;

    case Opcode::F64Abs:
      WriteSimpleUnaryExpr(expr.opcode, "F64Abs");
      break;

    case Opcode::F32Sqrt:
      WriteSimpleUnaryExpr(expr.opcode, "Sqr");
      break;

    case Opcode::F64Sqrt:
      WriteSimpleUnaryExpr(expr.opcode, "F64Sqrt");
      break;

    case Opcode::F32Ceil:
      WriteSimpleUnaryExpr(expr.opcode, "F32Ceil");
      break;

    case Opcode::F64Ceil:
      WriteSimpleUnaryExpr(expr.opcode, "F64Ceil");
      break;

    case Opcode::F32Floor:
      WriteSimpleUnaryExpr(expr.opcode, "F32Floor");
      break;

    case Opcode::F64Floor:
      WriteSimpleUnaryExpr(expr.opcode, "F64Floor");
      break;

    case Opcode::F32Trunc:
      WriteSimpleUnaryExpr(expr.opcode, "F32Trunc");
      break;

    case Opcode::F64Trunc:
      WriteSimpleUnaryExpr(expr.opcode, "F64Trunc");
      break;

    case Opcode::F32Nearest:
      WriteSimpleUnaryExpr(expr.opcode, "F32Nearest");
      break;

    case Opcode::F64Nearest:
      WriteSimpleUnaryExpr(expr.opcode, "F64Nearest");
      break;

    case Opcode::I32Extend8S:
      WriteSimpleUnaryExpr(expr.opcode, "I32Extend8S");
      break;

    case Opcode::I32Extend16S:
      WriteSimpleUnaryExpr(expr.opcode, "I32Extend16S");
      break;

    case Opcode::I64Extend8S:
      WriteSimpleUnaryExpr(expr.opcode, "I64Extend8S");
      break;

    case Opcode::I64Extend16S:
      WriteSimpleUnaryExpr(expr.opcode, "I64Extend16S");
      break;

    case Opcode::I64Extend32S:
      WriteSimpleUnaryExpr(expr.opcode, "I64Extend32S");
      break;

    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(const TernaryExpr& expr) {
  switch (expr.opcode) {
    case Opcode::V128BitSelect: {
      Type result_type = expr.opcode.GetResultType();
      Write(StackVar(2, result_type), " = ", "v128.bitselect", "(", StackVar(0),
            ", ", StackVar(1), ", ", StackVar(2), ")", Newline());
      DropTypes(3);
      PushType(result_type);
      break;
    }
    default:
      BRS_UNREACHABLE;
  }
}

void CWriter::Write(const SimdLaneOpExpr& expr) {
  Type result_type = expr.opcode.GetResultType();

  switch (expr.opcode) {
    case Opcode::I8X16ExtractLaneS:
    case Opcode::I8X16ExtractLaneU:
    case Opcode::I16X8ExtractLaneS:
    case Opcode::I16X8ExtractLaneU:
    case Opcode::I32X4ExtractLane:
    case Opcode::I64X2ExtractLane:
    case Opcode::F32X4ExtractLane:
    case Opcode::F64X2ExtractLane: {
      Write(StackVar(0, result_type), " = ", expr.opcode.GetName(), "(",
            StackVar(0), ", lane Imm: ", expr.val, ")", Newline());
      DropTypes(1);
      break;
    }
    case Opcode::I8X16ReplaceLane:
    case Opcode::I16X8ReplaceLane:
    case Opcode::I32X4ReplaceLane:
    case Opcode::I64X2ReplaceLane:
    case Opcode::F32X4ReplaceLane:
    case Opcode::F64X2ReplaceLane: {
      Write(StackVar(1, result_type), " = ", expr.opcode.GetName(), "(",
            StackVar(0), ", ", StackVar(1), ", lane Imm: ", expr.val, ")",
            Newline());
      DropTypes(2);
      break;
    }
    default:
      BRS_UNREACHABLE;
  }

  PushType(result_type);
}

void CWriter::Write(const SimdShuffleOpExpr& expr) {
  Type result_type = expr.opcode.GetResultType();
  Write(StackVar(1, result_type), " = ", expr.opcode.GetName(), "(",
        StackVar(1), " ", StackVar(0), ", lane Imm: $0x%08x %08x %08x %08x",
        expr.val.u32(0), expr.val.u32(1), expr.val.u32(2), expr.val.u32(3), ")",
        Newline());
  DropTypes(2);
  PushType(result_type);
}

void CWriter::Write(const LoadSplatExpr& expr) {
  assert(module_->memories.size() == 1);
  Memory* memory = module_->memories[0];

  Type result_type = expr.opcode.GetResultType();
  Write(StackVar(0, result_type), " = ", expr.opcode.GetName(), "(",
        ExternalPtr(memory->name), ", (", StackVar(0));
  if (expr.offset != 0)
    Write(" + ", expr.offset);
  Write("));", Newline());
  DropTypes(1);
  PushType(result_type);
}

void CWriter::WriteCSource() {
  stream_ = brs_stream_;
  WriteFuncDeclarations();
  WriteImports();
  WriteGlobals();
  WriteMemories();
  WriteDataInitializers();
  WriteTables();
  WriteElemInitializers();
  WriteInitExports();
  WriteFuncs();
  WriteInit();
}

Result CWriter::WriteModule(const Module& module) {
  WABT_USE(options_);
  module_ = &module;
  WriteCSource();
  return result_;
}

}  // end anonymous namespace

Result WriteBrs(Stream* stream,
                const Module* module,
                const WriteCOptions& options) {
  CWriter c_writer(stream, options);
  return c_writer.WriteModule(*module);
}

}  // namespace wabt
