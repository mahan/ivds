
class DocumentRef
  constructor: (@collection, @documentId, @version=-1) ->
    @version = parseInt(""+@version)
    #console.log "DocumentRef(@collection=#{@collection}, @documentId=#{@documentId}, @version=#{@version})"

class BackendIntf
  constructor: () ->

  store: (documentRef, documentBody, fn) ->
    throw new Exception('BackendIntf.store() - not implemented')

  retrieve: (documentRef, fn) ->
    throw new Exception('BackendIntf.retrieve() - not implemented')

  currentversion: (documentRef, fn) ->
    throw new Exception('BackendIntf.currentVersion() - not implemented')

module.exports = {
  DocumentRef
  BackendIntf
}
