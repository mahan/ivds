
#Immutable Versioned Document Store

How?

	1. Choose and configure your backend: Redis, ... roll your own.
	2. Choose a collection name.
	3. Start storing and retrieving documents.



Why?

Immutability is a wonderful thing, both for parallell processing as well as
scalability.

A certain version of a document, after it's creation, is exactly that and
nothing more or less regardless of when you ask for it.

Versioning combined with immutability reduces the need for (and possibly length
of) transactions, as a process is referencing data that will never change.

Example:

In a classical RDBMs based system transactions might be used to make sure
that certain data in an Order system don't change while generating an
Invoice based on that data to guarantee consistency between Orders and
Invoices.

Now imagine that transactions between the Invoice system and the Order system
are not available, but that the orders are Immutable and Versioned:

An Invoice can now be created based on the latest Order version available,
referencing it.

Even if the Order data was to change during the Invoice generation the Invoice
is still correct for the Order Version it's referencing.


Command line usage:

	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is the document v1' localhost:3000/api/ivds/v1/invoice/10000
	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is the document v2' localhost:3000/api/ivds/v1/invoice/10000
	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is the document v3' localhost:3000/api/ivds/v1/invoice/10000
	curl -sS localhost:3000/api/ivds/v1/invoice/10000
	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is another document v1' localhost:3000/api/ivds/v1/invoice/10001
	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is another document v2' localhost:3000/api/ivds/v1/invoice/10001
	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is another document v3' localhost:3000/api/ivds/v1/invoice/10001
	curl -sS -H "Content-Type: text/plain" -X POST -d 'This is another document v4' localhost:3000/api/ivds/v1/invoice/10001
	curl -sS localhost:3000/api/ivds/v1/currentversion/invoice/10001
