/* global cy */
/// <reference types="cypress" />

context('Visiting a legacy URL', () => {
    it('redirects to the new index route', () => {
      cy.visit('index.html?action=search&type=name&q=tei')
      cy.url().should('equal', 'http://localhost:8080/exist/apps/fundocs/?action=search&where=everywhere&q=tei')
    })
    it('redirects to the new view route', () => {
      cy.visit('view.html?uri=http://exist-db.org/xquery/file&function=file:sync&arity=3&location=java:org.exist.xquery.modules.file.FileModule')
      cy.url().should('equal', 'http://localhost:8080/exist/apps/fundocs/view?location=java%3Aorg.exist.xquery.modules.file.FileModule&uri=http%3A%2F%2Fexist-db.org%2Fxquery%2Ffile&function=file%3Async')
    })
    it('redirects to the new browse URL', () => {
      cy.visit('browse.html?w3c=true&appmodules=true')
      cy.url().should('equal', 'http://localhost:8080/exist/apps/fundocs/browse?w3c=true&appmodules=true')
    })
})
