/* global cy */
/// <reference types="cypress" />

context('Function Documentation', () => {
  beforeEach(() => {
    cy.visit('')
  })

  describe('landing page', () => {
    it('should contain major parts', () => {
      cy.get('.navbar')
        .contains('Home')
      cy.get('h1')
        .contains('Function Documentation')
      cy.get('#fun-query-form')
        .should('exist')
    })
  })

  describe('simple search', () => {
    it('should find article with extended markdown contents and code highlighting', () => {
      cy.get('#query-field')
        .type('file:sync')
      cy.get('.function-head > h4')
        .should('exist')
        .click()
      // code is highlighted 
      cy.get('.language-xquery')
        .should('exist')
      // button is visible
      cy.get('.extended-docs')
        .should('exist')
        .click()
      // displays MD 
      cy.get('zero-md')
        .should('exist')
    })
  })

  describe('browse', () => {
    it('should find local modules', () => {
      cy.get('#browse')
        .click()
      cy.get('.form-inline > .btn')
        .should('be.visible')
      // check module from fundocs itself 
      cy.get('#modules')
        .contains('http://exist-db.org/xquery/docs')
        .click()
      cy.get('.module')
        .should('exist')
    })
  })
})
