// SPDX-License-Identifier: GPL-3.0-or-later
//
// ixcc: compile one IW7 GSC script the way iw7-mod's runtime loader does.
//
// iw7-mod compiles custom scripts in-game with an embedded gsc-tool IW7 server
// context in production mode, after registering its own extension built-ins
// (print, va, replacefunc, file I/O, ...) with func_add/meth_add.  Stock
// gsc-tool does not know those names, so it rejects scripts that work in-game.
// ixcc reproduces the loader: same context, same extension registration scheme
// (iw7-mod: function ids from 807, method ids from 0x8000 + 1484), and writes
// the result in gsc-tool's .gscbin container so `gsc-tool -m disasm` can read it.
//
// It links against gsc-tool (GPL-3.0), hence this file's licence.  It is a
// build-time verification tool only and is not part of the mod.
//
// usage: ixcc <extensions.txt> <script-root> <relative/script.gsc> <out.gscbin> [stock-root]
//   extensions.txt  lines of "function <name>" / "method <name>" (# comments allowed)
//   script-root     directory that relative script and #include paths resolve against
//   stock-root      optional directory of stock IW7 sources used for #include fallbacks

#include "xsk/stdinc.hpp"
#include <sstream>
#include "xsk/utils/file.hpp"
#include "xsk/utils/zlib.hpp"
#include "xsk/gsc/engine/iw7.hpp"

namespace fs = std::filesystem;

namespace
{
    constexpr std::uint16_t first_custom_function = 807;
    constexpr std::uint16_t first_custom_method = 0x8000 + 1484;

    struct extension
    {
        std::string kind;
        std::string name;
    };

    auto read_extensions(fs::path const& path) -> std::vector<extension>
    {
        std::ifstream in(path);
        if (!in)
        {
            throw std::runtime_error("cannot read extensions file " + path.string());
        }

        std::vector<extension> result;
        std::string line;
        while (std::getline(in, line))
        {
            if (line.empty() || line[0] == '#')
            {
                continue;
            }

            std::istringstream fields(line);
            extension entry;
            fields >> entry.kind >> entry.name;
            if (entry.kind != "function" && entry.kind != "method")
            {
                throw std::runtime_error("bad extensions line: " + line);
            }

            result.push_back(entry);
        }

        return result;
    }

    // gsc-tool's .gscbin container (xsk::gsc::asset::serialize; the layout is the same in
    // both pinned versions, only the struct's field names differ):
    // "GSC\0", u32 compressed stack length, u32 stack length, u32 bytecode length,
    // zlib-compressed stack, bytecode.
    auto serialize_gscbin(xsk::gsc::buffer const& bytecode, xsk::gsc::buffer const& stack) -> std::vector<std::uint8_t>
    {
        auto compressed = xsk::utils::zlib::compress(std::vector<std::uint8_t>(stack.data, stack.data + stack.size));
        const auto put_u32 = [](std::vector<std::uint8_t>& out, std::uint32_t value)
        {
            for (auto i = 0; i < 4; i++)
            {
                out.push_back(static_cast<std::uint8_t>(value >> (8 * i)));
            }
        };

        std::vector<std::uint8_t> out{ 'G', 'S', 'C', 0 };
        put_u32(out, static_cast<std::uint32_t>(compressed.size()));
        put_u32(out, static_cast<std::uint32_t>(stack.size));
        put_u32(out, static_cast<std::uint32_t>(bytecode.size));
        out.insert(out.end(), compressed.begin(), compressed.end());
        out.insert(out.end(), bytecode.data, bytecode.data + bytecode.size);
        return out;
    }

    auto register_extensions(xsk::gsc::iw7::context& ctx, std::vector<extension> const& extensions) -> void
    {
        auto next_function = first_custom_function;
        auto next_method = first_custom_method;

        for (auto const& entry : extensions)
        {
            if (entry.kind == "function" && !ctx.func_exists(entry.name))
            {
                ctx.func_add(entry.name, next_function++);
            }
            else if (entry.kind == "method" && !ctx.meth_exists(entry.name))
            {
                ctx.meth_add(entry.name, next_method++);
            }
        }
    }
}

auto main(int argc, char** argv) -> int
{
    if (argc < 5)
    {
        std::cerr << "usage: ixcc <extensions.txt> <script-root> <relative/script.gsc> <out.gscbin> [stock-root]\n";
        return 2;
    }

    const fs::path extensions_file = argv[1];
    const fs::path script_root = argv[2];
    const std::string relative = argv[3];
    const fs::path output = argv[4];
    const fs::path stock_root = argc > 5 ? fs::path{ argv[5] } : fs::path{};

    try
    {
        xsk::gsc::iw7::context ctx(xsk::gsc::instance::server);

        ctx.init(xsk::gsc::build::prod, [&](xsk::gsc::context const*, std::string const& included) -> std::pair<xsk::gsc::buffer, std::vector<std::uint8_t>>
        {
            for (auto const& base : { script_root, stock_root })
            {
                if (!base.empty() && fs::exists(base / included))
                {
                    return { {}, xsk::utils::file::read(base / included) };
                }
            }

            throw std::runtime_error("could not load gsc file '" + included + "'");
        });

        register_extensions(ctx, read_extensions(extensions_file));

        auto source = xsk::utils::file::read(script_root / relative);
        const auto script_name = fs::path{ relative }.replace_extension().generic_string();
        const auto assembly = ctx.compiler().compile(script_name, source);
        const auto [bytecode, stack, devmap] = ctx.assembler().assemble(*assembly);

        fs::create_directories(output.parent_path().empty() ? fs::path{ "." } : output.parent_path());
        xsk::utils::file::save(output, serialize_gscbin(bytecode, stack));

        std::cout << "compiled " << relative << " bytecode=" << bytecode.size << " stack=" << stack.size << "\n";
        return 0;
    }
    catch (std::exception const& e)
    {
        std::cerr << "[ERROR] " << relative << ": " << e.what() << "\n";
        return 1;
    }
}
