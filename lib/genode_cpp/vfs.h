/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2018 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */

#ifndef _GENODE_CPP__VFS_H_
#define _GENODE_CPP__VFS_H_

/* Genode includes */
#include <vfs/simple_env.h>
#include <base/heap.h>
#include <base/attached_rom_dataspace.h>

extern void nim_handle_vfs_io_response(void*);

namespace Nim { class VfsEnv; }

class Nim::VfsEnv : public Vfs::Env
{
	/*
	 * TODO: wrap the Nim heap into a Genode::Allocator
	 */

	private:

		Genode::Env  &_env;
		Genode::Heap _heap { _env.pd(), _env.rm() };

		struct Io_response_handler : Vfs::Io_response_handler {
			void handle_io_response(Vfs::Vfs_handle::Context *p) override
			{
				nim_handle_vfs_io_response(p);
			}
		} _io_response_handler { };

		struct Watch_response_dummy : Vfs::Watch_response_handler {
			void handle_watch_response(Vfs::Vfs_watch_handle::Context*) override { }
		} _watch_dummy { };

		Vfs::Global_file_system_factory _fs_factory { _heap };

		Genode::Attached_rom_dataspace _config_rom { _env, "config" };

		Vfs::Dir_file_system _root_dir;

	public:

		VfsEnv(Genode::Env *env)
		:
			_env(*env),
			_root_dir(*this, _config_rom.xml().sub_node("nim").sub_node("vfs"),
			           _fs_factory)
		{ }

		void apply_config(Genode::Xml_node const &config)
		{
			_root_dir.apply_config(config);
		}

		Genode::Env       &env()       override { return _env; }
		Genode::Allocator &alloc()     override { return _heap; }
		Vfs::File_system  &root_dir()  override { return _root_dir; }

		Vfs::Io_response_handler    &io_handler()    override { return _io_response_handler; }
		Vfs::Watch_response_handler &watch_handler() override { return _watch_dummy; }

		Vfs::Directory_service::Open_result
		openFile(char const *path, unsigned mode, Vfs::Vfs_handle **handle, void *arg)
		{
			Vfs::Vfs_handle *h = nullptr;
			auto res = _root_dir.open(path, mode, handle, _heap);
			if (*handle)
				(*handle)->context = arg;
			return res;
		}
};

#endif
