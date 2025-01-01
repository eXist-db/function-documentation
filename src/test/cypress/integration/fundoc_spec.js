/* global cy */
/// <reference types="cypress" />

context('Function Documentation', () => {
  beforeEach(() => {
    cy.visit('')
    // TODO: Generate index in beforeAll
  })
  describe('landing page', () => {
    it('should show heading', () => {
      cy.get('h1')
        .contains('Function Documentation')
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
})
