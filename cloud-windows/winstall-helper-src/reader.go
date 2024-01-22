package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"sync"
	"time"
)

const CacheBlockSize = (32 * 1024 * 1024)
const FuseMaxBlockSize = (128 * 1024)
const CachesAmt = 8

type WebIsoReader struct {
	url      string
	totalEnd int64
}

type CacheEntry struct {
	From           int64
	To             int64
	LastUsed       int64
	CacheHits      int
	Valid          bool
	WaitingForData bool
	Content        [CacheBlockSize]byte
	mutex          sync.Mutex
}

var cache = make([]CacheEntry, CachesAmt)

func (r *WebIsoReader) doRangeFetch(from int64, to int64, into []byte) (int, error) {
	if r.totalEnd != 0 && to > r.totalEnd {
		to = r.totalEnd
	}

	var len = to - from

	var req, _ = http.NewRequest("GET", r.url, nil)
	req.Header.Set("Range", fmt.Sprintf("bytes=%d-%d", from, to))

	var resp, err = http.DefaultClient.Do(req)

	if err != nil {
		log.Println(err)
		return -1, err
	}

	if resp.StatusCode != 206 {
		err = &HttpStatusCodeError{StatusCode: resp.StatusCode}
		log.Println(err)
		return -1, err
	}

	defer resp.Body.Close()
	readBytes, err := io.ReadFull(resp.Body, into[:len])
	return readBytes, err
}

func (r *WebIsoReader) fetchCacheBlock(begin int64) (int, error) {

	var oldestCache = 0

	for i := range cache {
		if cache[i].LastUsed < cache[oldestCache].LastUsed && !cache[i].WaitingForData {
			oldestCache = i
		}
	}

	cache[oldestCache].mutex.Lock()
	defer cache[oldestCache].mutex.Unlock()
	cache[oldestCache].From = begin
	cache[oldestCache].CacheHits = 0
	cache[oldestCache].To = begin + CacheBlockSize
	cache[oldestCache].Valid = false
	cache[oldestCache].WaitingForData = true

	if DoDebugPrint {
		log.Printf("assigned new cache... doing http req")
	}

	var readBytes, err = r.doRangeFetch(begin, begin+CacheBlockSize, cache[oldestCache].Content[:])

	cache[oldestCache].WaitingForData = false

	if err != nil {
		log.Println(err)
		return -1, err
	}

	cache[oldestCache].LastUsed = time.Now().Unix()
	cache[oldestCache].To = begin + int64(readBytes)
	cache[oldestCache].Valid = true

	return oldestCache, nil
}

func (r *WebIsoReader) ReadAt(p []byte, off int64) (int, error) {

	if len(p) < FuseMaxBlockSize {
		return r.doRangeFetch(off, off+int64(len(p)), p) // dont cache small reads
	}

	for i := range cache {
		var v = &cache[i]
		if off >= v.From && off+int64(len(p)) < v.To {

			v.mutex.Lock()

			if !v.Valid && !v.WaitingForData {
				v.mutex.Unlock()
				continue
			}

			defer v.mutex.Unlock()

			if DoDebugPrint {
				log.Printf("using cached block %x\n", v.From)
			}

			if v.CacheHits == 32 && (off+CacheBlockSize) < r.totalEnd { // after 32 cache hits assume we are reading linearly
				if DoDebugPrint {
					log.Printf("doin speculative fetch for %x-%x\n", v.To, v.To+CacheBlockSize)
				}
				go r.fetchCacheBlock(v.To - (1 * 1024 * 1024)) // speculatively already fetch the next block with 1mb overlap
			}

			v.CacheHits++

			var offsetInto = off - v.From
			var length = len(p)
			var subslice = v.Content[offsetInto:]
			subslice = subslice[:length]
			copy(p, subslice)
			return len(subslice), nil
		}
	}

	if DoDebugPrint {
		log.Printf("no cache hit creating new cached block for %x\n", off)
	}

	var oldest, err = r.fetchCacheBlock(off)

	if err != nil {
		log.Println(err)
		return -1, err
	}

	var offsetInto = off - cache[oldest].From
	var length = len(p)
	var subslice = cache[oldest].Content[offsetInto:]
	subslice = subslice[:length]
	copy(p, subslice)

	return int(min(int64(len(subslice)), cache[oldest].To-cache[oldest].From)), nil
}
