/* global cy */
/// <reference types="cypress" />

context('Visiting a legacy URL', () => {
    it('redirects to the new index route', () => {
      cy.visit('index.html', { qs: { action: 'search', type: 'name', q: 'tei'}})

      cy.location('pathname').should('eq', '/exist/apps/fundocs/')
      cy.location('search').should('include', 'action=search')
      cy.location('search').should('include', 'where=everywhere')
      cy.location('search').should('include', 'q=tei')
    })
    it('redirects to the new view route', () => {
      cy.visit('view.html', { qs: { uri: 'http://exist-db.org/xquery/file', function: 'file:sync', location: 'java:org.exist.xquery.modules.file.FileModule'}})

      cy.location('pathname').should('eq', '/exist/apps/fundocs/view')
      cy.location('search').should('include', 'uri=http%3A%2F%2Fexist-db.org%2Fxquery%2Ffile')
      cy.location('search').should('include', 'function=file%3Async')
      cy.location('search').should('include', 'location=java%3Aorg.exist.xquery.modules.file.FileModule')
    })
    it('redirects to the new browse URL', () => {
      cy.visit('browse.html', { qs: { w3c: 'true', appmodules: 'true'}})

      cy.location('pathname').should('eq', '/exist/apps/fundocs/browse')
      cy.location('search').should('include', 'w3c=true')
      cy.location('search').should('include', 'appmodules=true')
    })
})
