
bi = require './backend_intf.coffee'

DocumentRef = bi.DocumentRef
BackendIntf = bi.BackendIntf

class InMemBackend extends BackendIntf

  @collections = {}

  store: (documentRef, documentBody, fn) ->
    unless documentRef.version == -1
      return fn("InMemBackend.store() - Version must be -1, i.e. undefined, but is: #{documentRef.version}. Version is generated during the store()")
    collections = InMemBackend.collections
    unless collections[documentRef.collection]?
      collections[documentRef.collection] = {}
    unless collections[documentRef.collection]?[documentRef.documentId]?
      collections[documentRef.collection][documentRef.documentId] = []
    collections[documentRef.collection][documentRef.documentId].push(documentBody)
    documentRef.version = collections[documentRef.collection][documentRef.documentId].length
    return fn(null, documentRef)

  retrieve: (documentRef, fn) ->
    collections = InMemBackend.collections
    unless collections[documentRef.collection]?[documentRef.documentId]?
      return fn('InMemBackend.retrieve() - document not found.')
    if documentRef.version == -1
      l = collections[documentRef.collection][documentRef.documentId]
      documentRef.version = l.length
      return fn(null, {documentRef: documentRef, documentBody: l[l.length-1]})
    else
      unless collections[documentRef.collection][documentRef.documentId][documentRef.version-1]?
        return fn('InMemBackend.retrieve() - document not found.')
      l = collections[documentRef.collection][documentRef.documentId]
      return fn(null, {documentRef: documentRef, documentBody: l[documentRef.version-1]})

  currentversion: (documentRef, fn) ->
    collections = InMemBackend.collections
    unless collections[documentRef.collection]?[documentRef.documentId]?
      return fn('InMemBackend.currentVersion() - document not found.')
    documentRef.version = collections[documentRef.collection][documentRef.documentId].length
    return fn(null, documentRef)

module.exports = {
  InMemBackend
}
