package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"syscall"
	"time"

	"github.com/hanwen/go-fuse/v2/fs"
	"github.com/hanwen/go-fuse/v2/fuse"
	"github.com/mogaika/udf"
)

type HttpStatusCodeError struct {
	StatusCode int
}

func (err *HttpStatusCodeError) Error() string {
	return fmt.Sprintf("bad status code: %d", err.StatusCode)
}

type httpRoot struct {
	fs.Inode
	backingReader io.ReaderAt
	size          int64
}

type httpFile struct {
	fs.Inode
	backingReader io.ReaderAt
	size          int64
}

var _ = (fs.NodeOpener)((*httpFile)(nil))
var _ = (fs.NodeGetattrer)((*httpFile)(nil))

func (hf *httpFile) Getattr(ctx context.Context, f fs.FileHandle, out *fuse.AttrOut) syscall.Errno {
	out.Mode = 07777
	out.Nlink = 1
	out.Mtime = uint64(time.Now().Unix())
	out.Atime = out.Mtime
	out.Ctime = out.Mtime
	out.Size = uint64(hf.size)
	const bs = 1024 * 1024 // 1mb
	out.Blksize = bs
	out.Blocks = (out.Size + bs - 1) / bs
	return 0
}

func (hf *httpFile) Open(ctx context.Context, flags uint32) (fs.FileHandle, uint32, syscall.Errno) {
	return nil, 0, 0
}

func (hf *httpFile) Read(ctx context.Context, f fs.FileHandle, dest []byte, off int64) (fuse.ReadResult, syscall.Errno) {
	// var clamp = int64(0)
	// if off+int64(len(dest)) > hf.size {
	// 	clamp = hf.size - off
	// }

	var readBytes, err = hf.backingReader.ReadAt(dest, off)

	if err == io.EOF {
		if readBytes == 0 {
			return nil, 0
		}
	} else if err != nil {
		log.Println(err)
		return nil, syscall.ECONNREFUSED
	}

	return fuse.ReadResultData(dest[:readBytes]), 0
}

func (r *httpRoot) OnAdd(ctx context.Context) {

	ch := r.NewPersistentInode(ctx, &httpFile{backingReader: r.backingReader, size: r.size}, fs.StableAttr{Ino: 2})
	r.AddChild("install.wim", ch, false)
}

func (r *httpRoot) Getattr(ctx context.Context, fh fs.FileHandle, out *fuse.AttrOut) syscall.Errno {
	out.Mode = 0755
	return 0
}

var _ = (fs.NodeGetattrer)((*httpRoot)(nil))
var _ = (fs.NodeOnAdder)((*httpRoot)(nil))

var DoDebugPrint = false

func main() {
	debug := flag.Bool("debug", false, "print debug data")
	url := flag.String("url", "", "which file to mount")
	mountpoint := flag.String("mount", "", "set mount point")
	flag.Parse()

	if *url == "" || *mountpoint == "" {
		log.Fatal("Usage:\n go-winstall-helper -h")
	}

	var r = WebIsoReader{url: *url}
	u := udf.NewUdfFromReader(&r)

	log.Println("locating install.wim offset from", r.url)

	var installOffset int64
	var installSize int64

	for _, f := range u.ReadDir(nil) {
		var name = f.Name()
		if name == "sources" {
			for _, f2 := range u.ReadDir(f.FileEntry()) {
				if f2.Name() == "install.wim" {
					installOffset = f2.GetFileOffset()
					installSize = f2.Size()
					break

				}
			}
			break
		}
	}

	log.Println("done. offset is", installOffset, "and size is", installSize)
	log.Println("downloading shiz")
	r.totalEnd = installOffset + installSize

	opts := &fs.Options{}
	opts.Name = "go-httpmount"
	opts.Debug = *debug
	DoDebugPrint = *debug
	opts.ExplicitDataCacheControl = true
	opts.MaxReadAhead = 1024 * 128
	opts.SingleThreaded = true
	server, err := fs.Mount(*mountpoint, &httpRoot{backingReader: io.NewSectionReader(&r, installOffset, installSize), size: installSize}, opts)

	if err != nil {
		log.Fatalf("Mount fail: %v\n", err)
	}

	server.Wait()
}
