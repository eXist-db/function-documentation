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
        .type('file:sync{enter}')
      cy.get('.function-head')
        .should('exist')
        .click()
      cy.url()
        .should('include', 'q=file')
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

  describe('searching everywhere includes parameter description', () => {
    it('should find file:sync with search term "exist_home"', () => {
      cy.get('#query-field')
        .type('exist_home{enter}')
      cy.get('.function-head')
        .should('exist')
        .click()
      cy.url()
        .should('include', 'q=exist_home')
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

  describe('Searching for a specific function, map:keys', () => {
    it('should show the correct function signature', () => {
      cy.visit('?q=map%3Akeys').get('.signature')
        .should('have.text', 'map:keys($map as map(*)) as xs:anyAtomicType*')
    })
  })



  describe('browse', () => {
    it('should find local modules', () => {
      cy.get('#browse')
        .click()
      cy.get('.form-inline > .btn')
        .should('be.visible')
      cy.get('[name=appmodules]')
        .check()
      cy.get('.form-inline > .btn')
        .click()
      // check module from fundocs itself 
      cy.get('#modules')
        .contains('http://exist-db.org/apps/fundocs/generate')
        .click()
      cy.get('.module')
        .should('exist')
    })
  })

})
