
class RollbackTest : Test {
  File path := File(`data/`)
  Str name := "data"

  override Void setup() {
    path.delete
  }

  private Str readPageContent(PageMgr store, Int transId, Int pageId) {
     page := store.getPage(transId, pageId)
     page.buf.seek(0)
     in := page.buf.in
     str := in.readUtf
     return str
  }

  private Void writePageContent(PageMgr store, Int transId, Page page, Str str) {
     page.verifyBuf
     page.buf.seek(0)
     out := page.buf.out
     out.writeUtf(str)
     out.close
     page.verifyBuf
     store.updatePage(transId, page)
  }

  private Void read(Int transId, Str p1, Str p2) {
     store := TransPageMgr(path, name)
     store.dump
     store.begin(transId)

     str := readPageContent(store, transId, 0)
     verifyEq(str, p1)

     str2 := readPageContent(store, transId,  1)
     verifyEq(str2, p2)

     store.close
     echo("--")
  }

  private Void write() {

     Int transId := 0

     store := TransPageMgr(path, name)
     store.begin(transId)

     page := store.createPage(transId)
     writePageContent(store, transId, page, "Hello")

     page2 := store.createPage(transId)
     writePageContent(store, transId, page2, "World")

     store.commit(transId)

     store.close
     store.dump
     echo("--")
  }

  private Void update() {
     Int transId := 2

     store := TransPageMgr(path, name)
     store.begin(transId)

     page := store.getPage(transId, 0)
     writePageContent(store, transId, page, "Update")

     str := readPageContent(store, transId, 0)
     verifyEq(str, "Update")

     store.flush
     store.rollback(transId)
     str = readPageContent(store, transId, 0)
     verifyEq(str, "Hello")

     store.close
     store.dump
     echo("--")
  }

  Void testUpdate() {
    write
    update
    read(3, "Hello", "World")
  }

  private Void delete() {
     Int transId := 3

     store := TransPageMgr(path, name)
     store.begin(transId)

     page := store.getPage(transId, 0)
     store.deletePage(transId, page, page)

     page2 := store.createPage(transId)
     writePageContent(store, transId, page2, "Delete")

     str := readPageContent(store, transId, 0)
     verifyEq(str, "Delete")

     store.rollback(transId)

     str2 := readPageContent(store, transId, 0)
     verifyEq(str2, "Hello")

     str3 := readPageContent(store, transId,  1)
     verifyEq(str3, "World")

     store.close
     store.dump
     echo("--")
  }

  Void testDelete() {
    write
    delete
    read(4, "Hello", "World")
  }

}